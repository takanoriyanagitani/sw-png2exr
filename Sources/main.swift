import class CoreImage.CIContext
import class CoreImage.CIImage
import class Foundation.ProcessInfo
import struct Foundation.URL

enum PngToExrErr: Error {
  case unableToLoadImage(String)
  case invalidArgument(String)
  case unimplemented(String)
}

typealias UrlToImage = (URL) -> Result<CIImage, Error>

func UrlToImg(_ url: URL) -> Result<CIImage, Error> {
  let oimg: CIImage? = CIImage(contentsOf: url)
  guard let img = oimg else {
    return .failure(PngToExrErr.unableToLoadImage("\( url )"))
  }
  return .success(img)
}

typealias ImageWriter = (CIImage) -> Result<(), Error>

typealias ImageToUrl = (URL) -> ImageWriter

func ImgToUrlNew(ictx: CIContext) -> ImageToUrl {
  return {
    let url: URL = $0
    return {
      let img: CIImage = $0
      return Result(catching: {
        try ictx.writeOpenEXRRepresentation(
          of: img,
          to: url,
          options: [:]
        )
      })
    }
  }
}

func EnvValByKey(_ key: String) -> Result<String, Error> {
  let values: [String: String] = ProcessInfo.processInfo.environment
  let oval: String? = values[key]
  guard let val = oval else {
    return .failure(PngToExrErr.invalidArgument("env val missing: \( key )"))
  }
  return .success(val)
}

func Compose<T, U, V>(
  _ f: @escaping (T) -> Result<U, Error>,
  _ g: @escaping (U) -> Result<V, Error>
) -> (T) -> Result<V, Error> {
  return {
    let t: T = $0
    let ru: Result<U, _> = f(t)
    return ru.flatMap {
      let u: U = $0
      return g(u)
    }
  }
}

func str2url(_ s: String) -> URL { URL(fileURLWithPath: s) }

func ipngUrl() -> Result<URL, Error> {
  Compose(EnvValByKey, { .success(str2url($0)) })("ENV_I_PNG_FILENAME")
}

func oexrUrl() -> Result<URL, Error> {
  Compose(EnvValByKey, { .success(str2url($0)) })("ENV_O_EXR_FILENAME")
}

func ipng() -> Result<CIImage, Error> {
  let iurl: Result<URL, _> = ipngUrl()
  return iurl.flatMap { UrlToImg($0) }
}

func sub() -> Result<(), Error> {
  let ictx: CIContext = CIContext()
  let i2url: ImageToUrl = ImgToUrlNew(ictx: ictx)
  let ourl: Result<URL, _> = oexrUrl()

  let iwtr: Result<ImageWriter, _> = ourl.map { i2url($0) }

  let rimg: Result<CIImage, _> = ipng()

  return iwtr.flatMap {
    let wtr: ImageWriter = $0
    return rimg.flatMap { wtr($0) }
  }
}

@main
struct PngToExr {
  static func main() {
    do {
      try sub().get()
    } catch {
      print("\( error )")
    }
  }
}
