import Foundation
import Vision
import AppKit
import CoreImage

try "".write(toFile: "/Users/lokmjj3/Desktop/Coding stuff/TwokindsWordCountSwiftTest/Test/Output.txt", atomically: false, encoding: .utf8)

func processImages(inDirectory directory: URL) {
    let fileManager = FileManager.default
    let fileTypes = ["jpg", "jpeg", "png"]
    guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: nil)?.allObjects as? [URL] else { return }
    
    let sortedURLs = enumerator
        .filter { fileTypes.contains($0.pathExtension.lowercased()) }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

    for fileURL in sortedURLs {
        guard let image = NSImage(contentsOf: fileURL) else { continue }
        let words = getWords(from: image, thing: fileURL.lastPathComponent)
    }
}

//TESTT        ytugihwjehfytugihjohgyufydrtfyguhijojhiugyftdrfyguiojugyftdrsetfyuiouiytrd
func saveWordsToFile(_ words: [String],_ PageNum: String) {
    let path = "/Users/lokmjj3/Desktop/Coding stuff/TwokindsWordCountSwiftTest/Test/Output.txt"

    do {
        let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: path))
        fileHandle.seekToEndOfFile()
        fileHandle.write("\n\n".data(using: .utf8)!) // add a newline before appending the words
        fileHandle.write("\(PageNum)\n".data(using: .utf8)!)
        fileHandle.write(words.joined(separator: "     ").data(using: .utf8)!)
        fileHandle.closeFile()
    } catch {
        print("Error saving words to file: \(error.localizedDescription)")
    }
}

func getWords(from image: NSImage, thing fileURL: String) -> [String] {
    // Convert the NSImage to a CIImage
    guard let ciImage = CIImage(data: image.tiffRepresentation!) else {
        print("Error converting NSImage to CIImage")
        return []
    }
    
    // Create a brightness filter to make pixels less bright than 230 black
    let brightnessFilter = CIFilter(name: "CIColorControls")!
    brightnessFilter.setValue(ciImage, forKey: kCIInputImageKey)
    brightnessFilter.setValue(NSNumber(value: -0.4), forKey: kCIInputBrightnessKey)
    brightnessFilter.setValue(NSNumber(value: 2), forKey: kCIInputContrastKey)

    // Get the output image from the brightness filter
    guard let outputImage = brightnessFilter.outputImage else {
        print("Error getting output image from brightness filter")
        return []
    }

    // Convert the output image to a CGImage
    let context = CIContext(options: nil)
    guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
        print("Error converting CIImage to CGImage")
        return []
    }
    
    // Create a Vision request to recognize text
    let request = VNRecognizeTextRequest { request, error in
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        
        // Filter out non-word results
        let words = observations
            .compactMap { observation in
                return observation.topCandidates(1).first?.string.lowercased()
            }
            .filter { word in
                // A word can contain letters, digits, and the characters ,.?!- and be at least one character long
                return word.rangeOfCharacter(from: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789,.?!- ")) != nil && !word.trimmingCharacters(in: .whitespaces).isEmpty
            }
        
        // Filter out non-English words
        let tagger = NSLinguisticTagger(tagSchemes: [.language], options: 0)
        tagger.string = words.joined(separator: " ")
        let language = tagger.dominantLanguage ?? "und"
        if language == "en" {
            saveWordsToFile(words, fileURL)
            print("Done \(fileURL)")
        }
    }

    // Create a Vision request handler
    let requestHandler = VNImageRequestHandler(cgImage: cgImage)

    // Perform the request
    do {
        try requestHandler.perform([request])
    } catch {
        print("Error performing OCR on image: \(error.localizedDescription)")
        return []
    }

    return []
}
// Example usage:
let directoryURL = URL(fileURLWithPath: "/Users/lokmjj3/Desktop/Coding stuff/TwokindsWordCountSwiftTest/Test/TwokindsPages/Twokinds - without filler page")
processImages(inDirectory: directoryURL)
