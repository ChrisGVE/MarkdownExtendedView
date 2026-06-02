// MVPFixtures.swift
// MarkdownExtendedView
//
// Copyright 2025 Christian C. Berclaz
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

/// Canonical source for each of the 7 MVP diagram types (PRD D4). Shared by the
/// PNG/SVG render matrix (Task 19) and the perceptual snapshot suite (Task 17).
enum MVPFixtures {

    struct Case {
        let name: String
        let source: String
    }

    static let all: [Case] = [
        Case(name: "flowchart", source: """
        flowchart LR
        A[Start] --> B{Choice}
        B --> C[Yes]
        B --> D[No]
        """),
        Case(name: "sequence", source: """
        sequenceDiagram
        Alice->>Bob: Hello Bob
        Bob-->>Alice: Hi Alice
        """),
        Case(name: "class", source: """
        classDiagram
        Animal <|-- Dog
        Animal : +int age
        Dog : +bark()
        """),
        Case(name: "state", source: """
        stateDiagram-v2
        [*] --> Idle
        Idle --> Running
        Running --> [*]
        """),
        Case(name: "er", source: """
        erDiagram
        CUSTOMER ||--o{ ORDER : places
        ORDER ||--|{ LINE_ITEM : contains
        """),
        Case(name: "pie", source: """
        pie title Pets
        "Dogs" : 50
        "Cats" : 30
        """),
        Case(name: "gantt", source: """
        gantt
        title Plan
        dateFormat YYYY-MM-DD
        section Phase
        Task1 : a1, 2024-01-01, 30d
        """),
    ]
}
