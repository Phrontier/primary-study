import Foundation

struct ScriptAssembler {
    func assembleScript(for event: Event, using manifest: StudyManifest) -> EventScript? {
        guard let template = event.scriptTemplate else { return nil }

        let procedureLookup = Dictionary(uniqueKeysWithValues: manifest.procedureBlocks.map { ($0.id, $0) })
        let calloutLookup = Dictionary(uniqueKeysWithValues: manifest.calloutBlocks.map { ($0.id, $0) })

        let procedureSections = template.orderedProcedureBlockIDs.compactMap { blockID -> EventScriptSection? in
            guard let block = procedureLookup[blockID] else { return nil }
            return EventScriptSection(title: block.title, body: block.body)
        }

        let calloutSections = template.orderedCalloutBlockIDs.compactMap { blockID -> EventScriptSection? in
            guard let block = calloutLookup[blockID] else { return nil }
            return EventScriptSection(title: block.title, body: block.body)
        }

        let sections = procedureSections + calloutSections
        guard !sections.isEmpty else { return nil }

        return EventScript(title: template.title, sections: sections, notes: template.notes)
    }
}
