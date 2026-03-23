# Bug Lifecycle Diagram — Export as Image

**How to export image from Mermaid (horizontal):**
1. Copy the Mermaid code below
2. Paste it into [Mermaid Live Editor](https://mermaid.live) or Mermaid extension in VS Code
3. Export PNG/SVG → Save to `images/bug-lifecycle.png`

---

## Mermaid Code (horizontal, with color meaning)

```mermaid
flowchart LR
    A([Tester creates Bug]) --> B([NEW])
    B --> C{Configuration Error?}
    C -- Yes --> D([CLOSED])
    C -- No --> E([Auto-assign finds Dev])
    E --> F{Available Dev?}
    F -- No --> G([WAITING])
    G --> H([Manager manual assign])
    H --> I([ASSIGNED])
    F -- Yes --> I
    I --> J([IN PROGRESS])
    J --> K([FIXED])
    K --> L([Tester verify])
    L --> D

    %% Color legend:
    %% Blue: Waiting for action
    %% Orange: In progress
    %% Red: Fixed/waiting for confirmation
    %% Green: Closed/finished
    %% Purple: Waiting for manual assignment

    style B fill:#87ceeb,stroke:#1e90ff,stroke-width:2px
    style E fill:#87ceeb,stroke:#1e90ff,stroke-width:2px
    style G fill:#dda0dd,stroke:#8a2be2,stroke-width:2px
    style H fill:#dda0dd,stroke:#8a2be2,stroke-width:2px
    style I fill:#ffb347,stroke:#ff8c00,stroke-width:2px
    style J fill:#ffb347,stroke:#ff8c00,stroke-width:2px
    style K fill:#ff6961,stroke:#d7263d,stroke-width:2px
    style L fill:#ff6961,stroke:#d7263d,stroke-width:2px
    style D fill:#90ee90,stroke:#228b22,stroke-width:2px
```

### **Color Legend:**
- <span style="color:#1e90ff"><b>Blue</b></span>: New/pending action
- <span style="color:#ff8c00"><b>Orange</b></span>: In progress
- <span style="color:#d7263d"><b>Red</b></span>: Fixed/waiting for verification
- <span style="color:#228b22"><b>Green</b></span>: Closed/completed
- <span style="color:#8a2be2"><b>Purple</b></span>: Waiting for manual assignment

---

**After export:** Place the saved image as `bug-lifecycle.png` inside the `images/` folder so it displays in the slide.
