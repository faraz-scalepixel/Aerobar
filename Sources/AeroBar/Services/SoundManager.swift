import Foundation
import AVFoundation

public class SoundManager {
    public static let shared = SoundManager()
    
    private var singlePlayer: AVAudioPlayer?
    private var doublePlayer: AVAudioPlayer?
    
    private init() {
        prepareAudioBuffers()
    }
    
    public func playBeep(isDouble: Bool = false) {
        guard ACState.shared.soundEnabled else { return }
        
        DispatchQueue.main.async { [weak self] in
            if isDouble {
                self?.doublePlayer?.stop()
                self?.doublePlayer?.currentTime = 0
                self?.doublePlayer?.play()
            } else {
                self?.singlePlayer?.stop()
                self?.singlePlayer?.currentTime = 0
                self?.singlePlayer?.play()
            }
        }
    }
    
    private func prepareAudioBuffers() {
        if let singleData = generateBeepWav(frequencies: [2100], durationMs: 65, pauseMs: 0) {
            singlePlayer = try? AVAudioPlayer(data: singleData)
            singlePlayer?.prepareToPlay()
            singlePlayer?.volume = 0.45
        }
        
        if let doubleData = generateBeepWav(frequencies: [1950, 2450], durationMs: 50, pauseMs: 40) {
            doublePlayer = try? AVAudioPlayer(data: doubleData)
            doublePlayer?.prepareToPlay()
            doublePlayer?.volume = 0.5
        }
    }
    
    // Generates uncompressed 16-bit PCM WAV in memory
    private func generateBeepWav(frequencies: [Double], durationMs: Int, pauseMs: Int) -> Data? {
        let sampleRate: Double = 44100.0
        let bytesPerSample = 2
        let numChannels = 1
        
        var audioSamples = [Int16]()
        
        for (index, freq) in frequencies.enumerated() {
            let toneSamplesCount = Int((Double(durationMs) / 1000.0) * sampleRate)
            let attackReleaseSamples = min(toneSamplesCount / 6, 300)
            
            for i in 0..<toneSamplesCount {
                let t = Double(i) / sampleRate
                let rawSine = sin(2.0 * .pi * freq * t)
                
                // Smooth envelope to avoid clicks
                var envelope = 1.0
                if i < attackReleaseSamples {
                    envelope = Double(i) / Double(attackReleaseSamples)
                } else if i > toneSamplesCount - attackReleaseSamples {
                    envelope = Double(toneSamplesCount - i) / Double(attackReleaseSamples)
                }
                
                let sampleValue = Int16(rawSine * envelope * 0.75 * Double(Int16.max))
                audioSamples.append(sampleValue)
            }
            
            if index < frequencies.count - 1 && pauseMs > 0 {
                let pauseSamplesCount = Int((Double(pauseMs) / 1000.0) * sampleRate)
                audioSamples.append(contentsOf: repeatElement(0, count: pauseSamplesCount))
            }
        }
        
        let subChunk2Size = audioSamples.count * bytesPerSample
        let chunkSize = 36 + subChunk2Size
        
        var data = Data()
        // RIFF header
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        data.append(contentsOf: withUnsafeBytes(of: UInt32(chunkSize).littleEndian) { Array($0) })
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        
        // fmt subchunk
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) }) // Subchunk1Size (16 for PCM)
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })  // AudioFormat (1 for PCM)
        data.append(contentsOf: withUnsafeBytes(of: UInt16(numChannels).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        
        let byteRate = UInt32(sampleRate) * UInt32(numChannels) * UInt32(bytesPerSample)
        data.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        
        let blockAlign = UInt16(numChannels * bytesPerSample)
        data.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Array($0) }) // BitsPerSample
        
        // data subchunk
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        data.append(contentsOf: withUnsafeBytes(of: UInt32(subChunk2Size).littleEndian) { Array($0) })
        
        // samples
        for sample in audioSamples {
            data.append(contentsOf: withUnsafeBytes(of: sample.littleEndian) { Array($0) })
        }
        
        return data
    }
}
