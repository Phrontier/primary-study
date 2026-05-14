import Foundation

struct ContentRepository {
    private let bundle: Bundle
    private let manifestFileName: String
    private let quizBankFileName: String
    private let syllabusReferenceFileName: String
    private let resourceNamespace = "StudyAssets"

    init(
        bundle: Bundle = .main,
        manifestFileName: String = "StudyManifest",
        quizBankFileName: String = "QuizBank",
        syllabusReferenceFileName: String = "SyllabusEventReference"
    ) {
        self.bundle = bundle
        self.manifestFileName = manifestFileName
        self.quizBankFileName = quizBankFileName
        self.syllabusReferenceFileName = syllabusReferenceFileName
    }

    func loadManifest() -> StudyManifest {
        guard let url = bundle.url(forResource: manifestFileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(StudyManifest.self, from: data) else {
            return .placeholder
        }

        return manifest
    }

    func loadQuizBank() -> QuizBank {
        guard let url = bundle.url(forResource: quizBankFileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bank = try? JSONDecoder().decode(QuizBank.self, from: data) else {
            return .empty
        }

        let validQuestions = bank.questions.filter(\.isValid)
        return QuizBank(categories: bank.categories, questions: validQuestions)
    }

    func loadSyllabusEventReference() -> SyllabusEventReference {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let url = fileURL(for: "AppContent/\(syllabusReferenceFileName).json"),
           let data = try? Data(contentsOf: url),
           let reference = try? decoder.decode(SyllabusEventReference.self, from: data) {
            return reference
        }

        if let url = Bundle.main.url(forResource: syllabusReferenceFileName, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let reference = try? decoder.decode(SyllabusEventReference.self, from: data) {
            return reference
        }

        return .empty
    }

    func fileURL(for relativePath: String) -> URL? {
        guard let resourceRoot = bundle.resourceURL else { return nil }
        let namespacedCandidate = resourceRoot
            .appendingPathComponent(resourceNamespace, isDirectory: true)
            .appendingPathComponent(relativePath)

        if FileManager.default.fileExists(atPath: namespacedCandidate.path) {
            return namespacedCandidate
        }

        if let directURL = bundle.url(forResource: relativePath, withExtension: nil) {
            return directURL
        }

        let candidate = resourceRoot.appendingPathComponent(relativePath)
        return FileManager.default.fileExists(atPath: candidate.path) ? candidate : nil
    }

    static let preview = ContentRepository(bundle: .main)
}
