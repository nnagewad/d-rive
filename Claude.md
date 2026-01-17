# GUIDING PRINCIPLE THROUGHOUT
- Don't repeat yourself. That goes for code and design
- Always aim to refactor code
- Often check if there is opportunities to refactor and componentize

# Code Development Rules
- NEVER ever mention a co-authored-by or similar aspects. In particular, never mention the tool used to create the commit message or PR.
- Feel free to suggest improved folder structure.

# Code principles
- Simplicity: Write simple, straightforward code
- Readability: Make code easy to understand
- Performance: Consider performance without sacrificing readability
- Maintainability: Write code that's easy to update
- Testability: Ensure code is testable
- Reusability: Create reusable components and functions
- Less Code = Less Debt: Minimize code footprint

# Design principles
- Use the Dieter Ram's 10 Principles of Good Design as template to aspire to
- Use the guiding principles from Apple's Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines
- Designs will be coming from Figma with multiple screenshots
- Feel free to intervene and ask questions for clarity, can direct you to another artboard within Figma or can describe in text what I would like to achieve

# Dieter Ram's 10 Principles of Good Design
## 1. Good design is innovative
The possibilities for innovation are not, by any means, exhausted. Technological development is always offering new opportunities for innovative design. But innovative design always develops in tandem with innovative technology, and can never be an end in itself.
## 2. Good design makes a product useful
A product is bought to be used. It has to satisfy certain criteria, not only functional, but also psychological and aesthetic. Good design emphasises the usefulness of a product whilst disregarding anything that could possibly detract from it.
## 3. Good design is aesthetic
The aesthetic quality of a product is integral to its usefulness because products we use every day affect our person and our well-being. But only well-executed objects can be beautiful.
## 4. Good design makes a product understandable
It clarifies the products structure. Better still, it can make the product talk. At best, it is self-explanatory.
## 5. Good design is unobtrusive
Products fulfilling a purpose are like tools. They are neither decorative objects nor works of art. Their design should therefore be both neutral and restrained, to leave room for the users self-expression.
## 6. Good design is honest
It does not make a product more innovative, powerful or valuable than it really is. It does not attempt to manipulate the consumer with promises that cannot be kept.
## 7. Good design is long-lasting
It avoids being fashionable and therefore never appears antiquated. Unlike fashionable design, it lasts many years - even in today's throwaway society.
## 8. Good design is thorough down to the last detail
Nothing must be arbitrary or left to chance. Care and accuracy in the design process show respect towards the consumer.
## 9. Good design is environmentally friendly
Design makes an important contribution to the preservation of the environment. It conserves resources and minimises physical and visual pollution throughout the lifecycle of the product.
## 10. Good design is as little design as possible
Less, but better - because it concentrates on the essential aspects, and the products are not burdened with non-essentials. Back to purity, back to simplicity.

---

# Architecture Overhaul Plan - January 17, 2026

Two-part update (in order):
1. **UI Component System** - Figma designs → reusable SwiftUI components → screens
2. **Database Migration** - GitHub JSON → Supabase + local SQLite *(after UI complete)*

## Part 1: UI Component System

**Status**: Waiting for Figma designs

**Approach**:
1. Receive Figma designs via MCP (go through each page in Figma App)
2. Analyze for common patterns (rows, cards, buttons, typography, colors)
3. Document design tokens and component specs
4. Build shared component library (ensure that language is in SwiftUI and uses UI colors)
5. Assemble full screens from components

**Proposed Structure**:
```
Dérive/
├── Components/
│   ├── DesignTokens.swift      # Colors, fonts, spacing constants
│   ├── Rows/
│   ├── Buttons/
│   ├── Cards/
    ├── (Ensure that a preview is readily available in each file)
│   └── ...
├── Views/
│   └── (Build new UI using the Components. Ensure that a preview is ready available in each file)
```

## Part 2: Create new Database

**Current**: JSON on GitHub + local JSON cache
**Target**: Supabase PostgreSQL + local SwiftData/SQLite

**Schema**: Will determine once Components and UI have all been created.

**Rough plan of files to modify**:
- `Dérive/Services/CityService.swift` - Replace JSON with Supabase + SwiftData
- `Dérive/Models/City.swift` - Update to SwiftData @Model
- `Dérive/App/DériveApp.swift` - Add SwiftData modelContainer
- New: `SupabaseService.swift`, `CityModel.swift`, `GeofenceModel.swift`