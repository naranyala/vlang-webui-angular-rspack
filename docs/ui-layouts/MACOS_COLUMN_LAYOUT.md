# macOS Finder Column View Layout

**Created:** 2026-03-16  
**Version:** 2.0  
**Style:** Vertical Splits (Left/Middle/Right)

---

## Overview

This layout is inspired by **macOS Finder's column view**, featuring three vertical panes that allow users to navigate hierarchically through content, with nested WinBox.js windows for detailed interactions.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  ☰  🏠 Home › Authentication                    🔍 Search...   🔐 Auth 🗄️   │
├──────────┬────────────────────────────────────┬─────────────────────────────┤
│  📍      │  📋 Applications                   │  👁️ Preview                 │
│  Locations│                                   │                              │
│          │  ┌──────┐ ┌──────┐ ┌──────┐       │  ┌──────────────────────┐   │
│  ⭐      │  │ 🔐  │ │ 🗄️  │ │ 🔧  │       │  │         🔐            │   │
│  Fav     │  │ Auth │ │SQLite│ │Tools │       │  │                       │   │
│          │  └──────┘ └──────┘ └──────┘       │  │   Authentication      │   │
│  📱      │  ┌──────┐ ┌──────┐ ┌──────┐       │  │                       │   │
│  Apps    │  │ 📊  │ │ 🌐  │ │ ⚙️  │       │  │   Login & Register    │   │
│          │  │ Sys  │ │ Net  │ │ Proc │       │  │                       │   │
│  📄      │  └──────┘ └──────┘ └──────┘       │  │  [🚀 Open Window]    │   │
│  Docs    │                                   │  │  [ℹ️ More Info]      │   │
│          │                                   │  └──────────────────────┘   │
│  🪟 Win  │                                   │                              │
│  ◼ Auth  │                                   │  Quick Actions              │
│          │                                   │  📤 Share  📋 Copy          │
│  💭 No   │                                   │  🏷️ Tag    🗑️ Delete         │
│  windows │                                   │                              │
├──────────┴────────────────────────────────────┴─────────────────────────────┤
│  ● Connected  Items: 6    Drag splitters to resize columns    Windows: 0   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Layout Structure

### Three Vertical Columns

| Column | Default Width | Min | Max | Purpose |
|--------|---------------|-----|-----|---------|
| **Left** | 20% | 15% | 30% | Navigation/Locations |
| **Middle** | 45% | 30% | 60% | Content/Grid View |
| **Right** | 35% | 20% | 50% | Preview/Details |

### Horizontal Sections

| Section | Height | Purpose |
|---------|--------|---------|
| **Toolbar** | 52px | Navigation, search, actions |
| **Main Container** | Flex (remaining) | Three columns with splitters |
| **Status Bar** | 28px | Status, hints, counts |

---

## Component Details

### 1. Toolbar (Top)

**Structure:**
```
┌─────────────────────────────────────────────────────────────────┐
│  [☰]  🏠 Home › [Page]              [🔍 Search...]  [🔐] [🗄️] [✕] │
└─────────────────────────────────────────────────────────────────┘
```

**Sections:**

| Section | Components |
|---------|------------|
| **Left** | Sidebar toggle, Breadcrumb navigation |
| **Center** | Search bar with clear button |
| **Right** | Quick actions (Auth, SQLite), Close all |

**Features:**
- Breadcrumb shows current location
- Search filters middle column content
- Quick access buttons for common actions

---

### 2. Left Column - Navigation

**Finder-style sidebar with:**

#### Locations Section
```
📍 Locations
├── ⭐ Favorites         [2]
├── 📱 Applications      [6]
├── 📄 Documents         [0]
├── ⬇️ Downloads         [0]
└── 🗑️ Trash             [0]
```

#### Windows Section
```
🪟 Windows              [2]
├── ◼ Authentication
└── ◼ SQLite CRUD
```

**Collapsed State:**
```
┌────┐
│ ⭐ │
│ 📱 │
│ 📄 │
│ ⬇️ │
│ 🗑️ │
├────┤
│ 🪟 │
│ ◼  │
│ ◼  │
└────┘
```

**Navigation Items:**

| Item | Icon | Purpose |
|------|------|---------|
| Favorites | ⭐ | Quick access items |
| Applications | 📱 | All applications/features |
| Documents | 📄 | Document files |
| Downloads | ⬇️ | Downloaded items |
| Trash | 🗑️ | Deleted items |

---

### 3. Middle Column - Content View

**Two View Modes:**

#### Grid View (Default)
```
┌────────┬────────┬────────┐
│   🔐   │   🗄️   │   🔧   │
│  Auth  │ SQLite │ Tools  │
│ Login  │  DB    │ Debug  │
├────────┼────────┼────────┤
│   📊   │   🌐   │   ⚙️   │
│  Sys   │  Net   │  Proc  │
│ Monitor│ Stats  │ Manager│
└────────┴────────┴────────┘
```

#### List View
```
Name              Type        Date
─────────────────────────────────────
🔐 Authentication  Feature    2026-03-16
🗄️ SQLite CRUD    Feature    2026-03-16
🔧 DevTools       Tool       2026-03-15
📊 System Info    Monitor    2026-03-15
🌐 Network        Monitor    2026-03-14
⚙️ Processes      Tool       2026-03-14
```

**View Controls:**
- **Toggle View** (☰/▦) - Switch between grid/list
- **Refresh** (⟳) - Reload content

---

### 4. Right Column - Preview

**Preview Panel (when item selected):**
```
┌──────────────────────────────┐
│            🔐                │
│      Authentication          │
│   Login & Register System    │
├──────────────────────────────┤
│  Type:      Feature          │
│  Date:      2026-03-16       │
│  Status:    Active           │
├──────────────────────────────┤
│  [🚀 Open Window] [ℹ️ Info]  │
├──────────────────────────────┤
│  Quick Actions               │
│  📤 Share   📋 Copy          │
│  🏷️ Tag     🗑️ Delete        │
└──────────────────────────────┘
```

**Empty State:**
```
┌──────────────┐
│      👈      │
│  Select an   │
│  item to     │
│  preview     │
└──────────────┘
```

---

### 5. Vertical Splitters

**Appearance:**
```
Column 1  ║  Column 2  ║  Column 3
          ║            ║
      [====]      [====]
      Handle    Handle
```

**Behavior:**
- Hover: Highlights with accent color
- Drag: Resize adjacent columns
- Constraints: Min/max width enforced
- Cursor: Changes to `ew-resize`

**Resizing Logic:**

```typescript
// Left splitter
leftColumn = clamp(15, 30, startSize + deltaPercent)
middleColumn = 100 - leftColumn - rightColumn

// Middle splitter
middleColumn = clamp(30, 60, startSize + deltaPercent)
rightColumn = 100 - leftColumn - middleColumn
```

---

### 6. Status Bar (Bottom)

```
┌─────────────────────────────────────────────────────────────────┐
│ ● Connected  Items: 6    Drag to resize    Windows: 0  Zoom: 100%│
└─────────────────────────────────────────────────────────────────┘
```

**Sections:**

| Section | Content |
|---------|---------|
| **Left** | Connection status, item count |
| **Center** | Usage hints |
| **Right** | Window count, zoom level |

---

## WinBox.js Integration

### Window Behavior

**Opening Windows:**
1. Click "Open Window" in preview panel
2. Click toolbar quick action buttons
3. Double-click grid/list items

**Window Positioning:**
```typescript
viewport = {
  left: leftColumnWidth + 20,
  top: 100,      // Account for toolbar
  width: windowWidth - leftColumnWidth - 40,
  height: windowHeight - 140  // Account for toolbar + status
}

windowPosition = {
  x: viewport.left + (viewport.width - windowWidth) / 2,
  y: viewport.top + (viewport.height - windowHeight) / 2
}
```

**Window Features:**
- Centered in available viewport
- Respects column layout (doesn't overlap sidebar)
- Multiple windows can overlap
- Focus tracking updates sidebar

### Window Types

| Type | Size | Background | Content |
|------|------|------------|---------|
| **Auth** | 500×600 | Purple gradient | Login form |
| **SQLite** | 500×550 | Green gradient | CRUD operations |
| **Generic** | 600×550 | Card color | Placeholder |

---

## User Interactions

### Navigation Flow

```
1. Select location in left column
   ↓
2. Browse content in middle column (grid/list)
   ↓
3. Preview details in right column
   ↓
4. Click "Open Window" to interact
```

### Keyboard Shortcuts (Future)

| Shortcut | Action |
|----------|--------|
| `Cmd+B` | Toggle sidebar |
| `Cmd+F` | Focus search |
| `Cmd+1/2/3` | Switch view mode |
| `Cmd+W` | Close focused window |
| `Cmd+0` | Reset column sizes |

### Gestures (Touch)

| Gesture | Action |
|---------|--------|
| Swipe left/right | Navigate breadcrumb |
| Pinch | Zoom grid view |
| Tap | Select item |
| Double tap | Open window |

---

## State Management

### Component Signals

```typescript
class AppComponent {
  // Column sizes
  leftColumnSize = signal(20)
  middleColumnSize = signal(45)
  rightColumnSize = signal(35)
  
  // Column state
  leftColumnCollapsed = signal(false)
  
  // Navigation
  activeNavigation = signal('favorites')
  activeView = signal('home')
  searchQuery = signal('')
  viewMode = signal<'grid' | 'list'>('grid')
  selectedCard = signal<Card | null>(null)
  
  // Windows
  windowEntries = signal<WindowEntry[]>([])
}
```

### Computed State

```typescript
// Filter cards based on search
filteredCards = computed(() => {
  const query = searchQuery().toLowerCase()
  return TECH_CARDS.filter(card =>
    card.title.toLowerCase().includes(query) ||
    card.description.toLowerCase().includes(query)
  )
})

// Navigation items
navigationItems = computed(() => navItems())
```

---

## CSS Architecture

### Key Classes

```css
/* Layout */
.app-container          /* Main flexbox */
.main-container         /* Column container */
.column                 /* Base column */
.column--left           /* Left sidebar */
.column--middle         /* Middle content */
.column--right          /* Right preview */

/* Toolbar */
.toolbar                /* Top toolbar */
.toolbar__search        /* Search bar */
.toolbar__breadcrumb    /* Navigation path */

/* Splitters */
.splitter               /* Divider between columns */
.splitter--vertical     /* Vertical orientation */
.splitter__grip         /* Visual handle */

/* Views */
.grid-view              /* Grid layout */
.grid-item              /* Grid card */
.list-view              /* List layout */
.list-item              /* List row */

/* Preview */
.preview-panel          /* Detail view */
.info-row               /* Info table row */
.quick-actions__grid    /* Action buttons */

/* Status */
.status-bar             /* Bottom bar */
.status-indicator       /* Connection dot */
```

### Color Palette

```css
/* Backgrounds */
--bg-app: #1e1e2e
--bg-column: #2a2a3c
--bg-sidebar: rgba(30, 30, 46, 0.8)
--bg-header: rgba(0, 0, 0, 0.2)

/* Borders */
--border-light: rgba(255, 255, 255, 0.08)
--border-medium: rgba(255, 255, 255, 0.15)

/* Accents */
--accent-purple: linear-gradient(135deg, #667eea 0%, #764ba2 100%)
--accent-green: linear-gradient(135deg, #00b09b 0%, #96c93d 100%)
--accent-hover: rgba(102, 126, 234, 0.3)

/* Text */
--text-primary: rgba(255, 255, 255, 0.9)
--text-secondary: rgba(255, 255, 255, 0.6)
--text-tertiary: rgba(255, 255, 255, 0.4)
```

### Visual Effects

**Glassmorphism:**
```css
backdrop-filter: blur(20px);
background: rgba(30, 30, 46, 0.95);
```

**Shadows:**
```css
box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
```

**Animations:**
```css
transition: all 0.2s ease;
animation: fadeIn 0.3s ease;
animation: pulse 2s ease-in-out infinite;
```

---

## Responsive Behavior

### Desktop (> 1024px)

- Full three-column layout
- All splitters functional
- Search bar visible
- Full button labels

### Tablet (768px - 1024px)

- Narrower columns
- Reduced minimum widths
- Search bar maintained
- Icon-only buttons

### Mobile (< 768px)

```css
@media (max-width: 768px) {
  .main-container {
    flex-direction: column;  /* Stack vertically */
  }
  
  .column {
    width: 100%;
    max-height: 250px;
    border-bottom: 1px solid;
  }
  
  .splitter {
    cursor: ns-resize;  /* Vertical resize */
  }
  
  .toolbar__search {
    display: none;  /* Hide search */
  }
}
```

- Columns stack vertically
- Splitters become horizontal
- Search hidden
- Button labels hidden

---

## Accessibility

### ARIA Structure

```html
<header class="toolbar" role="banner">
  <nav aria-label="Breadcrumb">...</nav>
  <search role="search">...</search>
</header>

<main class="main-container" role="main">
  <aside class="column column--left" role="navigation" aria-label="Sidebar">
    <nav aria-label="Locations">...</nav>
    <nav aria-label="Windows">...</nav>
  </aside>
  
  <section class="column column--middle" role="region" aria-label="Content">
    <div role="grid">...</div>
  </section>
  
  <section class="column column--right" role="region" aria-label="Preview">
    <article aria-label="Item details">...</article>
  </section>
</main>

<footer class="status-bar" role="contentinfo">...</footer>
```

### Keyboard Navigation

```typescript
// Future implementation
const focusableElements = {
  toolbar: ['sidebar-toggle', 'breadcrumb', 'search', 'actions'],
  leftColumn: ['navigation-items', 'window-items'],
  middleColumn: ['grid-items', 'list-items', 'view-controls'],
  rightColumn: ['preview-actions', 'quick-actions'],
  statusBar: ['status-items'],
}
```

---

## Performance Optimizations

### Resize Performance

```typescript
// Use requestAnimationFrame for smooth resizing
onMouseMove(event: MouseEvent): void {
  if (!this.isResizing) return
  
  requestAnimationFrame(() => {
    const deltaX = event.clientX - this.resizeStartX
    const deltaPercent = (deltaX / window.innerWidth) * 100
    
    // Update sizes
    this.leftColumnSize.set(newSize)
  })
}
```

### Change Detection

- Angular signals for fine-grained reactivity
- Computed signals for derived state
- Only affected components update

### CSS Performance

```css
/* Hardware acceleration */
.column {
  will-change: flex-basis;
}

/* Avoid layout thrashing */
.grid-item:hover {
  transform: translateY(-2px);  /* Not margin */
}
```

---

## Files Modified

| File | Changes | Lines |
|------|---------|-------|
| `app.component.html` | New column layout | ~250 |
| `app.component.ts` | Column management, resizing | ~350 |
| `app.component.css` | Finder-style theming | ~800 |

---

## Comparison: Horizontal vs Vertical

| Aspect | Horizontal (v1) | Vertical (v2) |
|--------|-----------------|---------------|
| **Layout** | Top/Middle/Bottom | Left/Middle/Right |
| **Splitter Direction** | Horizontal (ns-resize) | Vertical (ew-resize) |
| **Navigation** | Top bar | Left sidebar |
| **Content Focus** | Full width | Column-based |
| **Preview** | Bottom pane | Right column |
| **Best For** | Dashboard views | File browsing |
| **Mobile** | Stack vertically | Stack vertically |

---

## Future Enhancements

### Column Features

1. **Column Persistence**
   - Save column sizes to localStorage
   - Restore on application load
   - Multiple layout presets

2. **Nested Columns**
   - Sub-columns within middle column
   - Expandable navigation tree
   - Breadcrumb navigation

3. **Column Tabs**
   - Multiple views per column
   - Tab switching
   - Drag-and-drop tabs

### Navigation Features

1. **Quick Look**
   - Spacebar preview (like macOS)
   - Image/video preview
   - Document preview

2. **Tags System**
   - Color-coded tags
   - Filter by tag
   - Smart folders

3. **Recent Items**
   - Recently opened
   - Recently modified
   - Quick access

### Window Features

1. **Window Tiling**
   - Snap to left/right
   - Quarter tiling
   - Window groups

2. **Window Tabs**
   - Tab multiple windows
   - Drag to reorder
   - Merge windows

3. **Expose/Overview**
   - Show all windows
   - Spatial arrangement
   - Search windows

---

## Browser Compatibility

| Browser | Version | Status |
|---------|---------|--------|
| Chrome | 120+ | ✅ Full support |
| Edge | 120+ | ✅ Full support |
| Firefox | 120+ | ✅ Full support |
| Safari | 17+ | ✅ Full support |

**Required Features:**
- `backdrop-filter` - Glassmorphism
- `flexbox` - Layout system
- `CSS Grid` - Grid view
- `CSS custom properties` - Theming
- `IntersectionObserver` - Lazy loading (future)

---

## Conclusion

The macOS Finder Column View layout provides:

✅ **Familiar navigation** - Three-column Finder-style interface  
✅ **Hierarchical browsing** - Navigate from locations → content → details  
✅ **Flexible resizing** - Drag splitters to customize column widths  
✅ **Responsive design** - Adapts to different screen sizes  
✅ **Nested windows** - WinBox.js windows for interactions  
✅ **Modern styling** - Glassmorphism, smooth animations  

This layout is ideal for applications that need to browse hierarchical data while maintaining context across multiple levels.

---

*Last Updated: 2026-03-16*  
*Version: 2.0*  
*Style: Vertical Splits (Left/Middle/Right)*
