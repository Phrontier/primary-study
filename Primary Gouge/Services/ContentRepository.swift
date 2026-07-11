import Foundation

struct ContentRepository {
    private let bundle: Bundle
    private let manifestFileName: String
    private let quizBankFileName: String
    private let syllabusReferenceFileName: String
    private let echoTrackFileName = "EchoTrack"
    private let echoSyllabusReferenceFileName = "EchoEventReference"
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

    func loadManifest(for track: SyllabusTrack) -> StudyManifest {
        var manifest = loadManifest()
        guard track.contentFallback == .echo,
              let overlay = loadEchoTrackManifest()
        else {
            return manifest
        }

        let basePhases = manifest.phases
        manifest.phases = overlay.phases.map { overlayPhase in
            guard let basePhase = basePhases.first(where: { $0.id == overlayPhase.id }) else {
                return overlayPhase
            }

            let categories = overlayPhase.categories.map { overlayCategory in
                guard overlayCategory.kind == .groundSchool,
                      let baseCategory = basePhase.categories.first(where: { $0.kind == .groundSchool })
                else {
                    return overlayCategory
                }

                return StudyCategory(
                    id: overlayCategory.id,
                    kind: overlayCategory.kind,
                    summary: overlayCategory.summary,
                    events: baseCategory.events + overlayCategory.events
                )
            }

            return Phase(
                id: overlayPhase.id,
                title: overlayPhase.title,
                summary: overlayPhase.summary,
                iconName: overlayPhase.iconName,
                categories: categories
            )
        }
        let existingIDs = Set(manifest.flashcards.map(\.id))
        manifest.flashcards.append(contentsOf: overlay.flashcards.filter { !existingIDs.contains($0.id) })
        return manifest
    }

    private func loadEchoTrackManifest() -> SyllabusTrackManifest? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        for relativePath in [
            "AppContent/Syllabi/\(echoTrackFileName).json",
            "Syllabi/\(echoTrackFileName).json"
        ] {
            if let url = fileURL(for: relativePath),
               let data = try? Data(contentsOf: url),
               let overlay = try? decoder.decode(SyllabusTrackManifest.self, from: data) {
                return overlay
            }
        }

        if let url = bundle.url(forResource: echoTrackFileName, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let overlay = try? decoder.decode(SyllabusTrackManifest.self, from: data) {
            return overlay
        }

        return nil
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

    func loadSyllabusEventReference(for track: SyllabusTrack = .delta) -> SyllabusEventReference {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if track.contentFallback == .echo {
            for relativePath in [
                "AppContent/Syllabi/\(echoSyllabusReferenceFileName).json",
                "Syllabi/\(echoSyllabusReferenceFileName).json"
            ] {
                if let url = fileURL(for: relativePath),
                   let data = try? Data(contentsOf: url),
                   let reference = try? decoder.decode(SyllabusEventReference.self, from: data) {
                    return reference
                }
            }

            if let url = bundle.url(forResource: echoSyllabusReferenceFileName, withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let reference = try? decoder.decode(SyllabusEventReference.self, from: data) {
                return reference
            }
        }

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
