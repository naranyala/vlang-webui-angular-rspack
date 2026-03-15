import { CommonModule } from '@angular/common';
import { Component, computed, inject, signal } from '@angular/core';
import { WinBoxService, type WinBoxInstance } from '../core/winbox.service';
import { type BottomPanelTab, type Card, TECH_CARDS, type WindowEntry } from '../models';
import { AuthComponent } from './auth/auth.component';
import { SqliteCrudComponent } from './sqlite/sqlite.component';

// Import styles with null guards
const styles: string = (require('./app.component.css?raw') as string) || '';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, AuthComponent, SqliteCrudComponent],
  template: require('./app.component.html?raw') as string,
  styles: [styles],
})
export class AppComponent {
  private readonly winboxService = inject(WinBoxService);

  topCollapsed = signal(false);
  bottomCollapsed = signal(true);
  activeCard = signal<1 | 2>(1);
  windowEntries = signal<WindowEntry[]>([]);

  bottomPanelTabs: BottomPanelTab[] = [
    { id: 'info', label: 'Info', icon: 'ℹ', content: 'Application info' },
  ];

  private existingBoxes: WinBoxInstance[] = [];
  private authWindowId = 'auth-window-1';
  private sqliteWindowId = 'sqlite-window-2';
  private resizeHandler: (() => void) | null = null;

  cards: Card[] = TECH_CARDS;

  hasFocusedWindow = computed(() => {
    return this.windowEntries().some(entry => entry.focused);
  });

  closeAllWindows(event?: Event): void {
    if (event) {
      event.stopPropagation();
    }
    this.closeAllBoxes();
    this.windowEntries.set([]);
  }

  ngOnInit(): void {
    this.closeAllBoxes();

    // Verify WinBox is available
    const winboxAvailable = this.winboxService.isAvailable() || !!(window as any).WinBox;

    if (typeof document !== 'undefined') {
      (window as any).__WINBOX_DEBUG = {
        serviceHasIt: this.winboxService.isAvailable(),
        windowHasIt: !!(window as any).WinBox,
        winboxConstructor: (window as any).WinBox || null,
        checked: new Date().toISOString(),
      };
    }

    // Listen for window resize events
    if (typeof window !== 'undefined') {
      this.resizeHandler = () => this.resizeAllWindows();
      window.addEventListener('resize', this.resizeHandler);
    }
  }

  ngOnDestroy(): void {
    if (typeof window !== 'undefined' && this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler);
      this.resizeHandler = null;
    }
  }

  closeAllBoxes(): void {
    const boxesToClose = [...this.existingBoxes];

    for (const box of boxesToClose) {
      if (box) {
        try {
          if (box.min) {
            box.restore();
          }
          box.focus();
          box.close(true);
        } catch {
          // Ignore errors
        }
      }
    }

    setTimeout(() => {
      const winboxElements = document.querySelectorAll('.winbox');
      winboxElements.forEach((el) => {
        try {
          el.remove();
        } catch {
          // Ignore errors
        }
      });

      this.existingBoxes = [];
      this.windowEntries.set([]);
    }, 50);
  }

  openAuthWindow(event?: Event): void {
    if (event) {
      event.stopPropagation();
    }
    this.createWindow(this.authWindowId, '🔐 Authentication', 'auth');
  }

  openSqliteWindow(event?: Event): void {
    if (event) {
      event.stopPropagation();
    }
    this.createWindow(this.sqliteWindowId, '🗄️ SQLite CRUD', 'sqlite');
  }

  private createWindow(windowId: string, title: string, type: 'auth' | 'sqlite'): void {
    const WinBoxConstructor = (window as any).WinBox;

    if (!WinBoxConstructor) {
      return;
    }

    // Check for existing window
    const existingBox = this.existingBoxes.find(box => box?.__windowId === windowId);
    if (existingBox) {
      if (existingBox.min) existingBox.restore();
      existingBox.focus();
      this.applyMaximizedState(existingBox);
      this.markWindowFocused(windowId, title);
      return;
    }

    try {
      const viewport = this.getAvailableViewport();
      const windowWidth = Math.min(500, viewport.width);
      const windowHeight = type === 'auth' ? Math.min(700, viewport.height) : Math.min(650, viewport.height);
      const x = viewport.left + (viewport.width - windowWidth) / 2;
      const y = viewport.top + (viewport.height - windowHeight) / 2;

      const box = new WinBoxConstructor({
        id: windowId,
        title: title,
        background: type === 'auth'
          ? 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
          : 'linear-gradient(135deg, #00b09b 0%, #96c93d 100%)',
        width: `${windowWidth}px`,
        height: `${windowHeight}px`,
        x: `${x}px`,
        y: `${y}px`,
        minwidth: 400,
        minheight: type === 'auth' ? 500 : 450,
        maxwidth: 600,
        maxheight: 800,
        html: `<div id="${type}-root-${windowId}" style="height: 100%; width: 100%;"></div>`,
      });

      if (!box) {
        return;
      }

      box.__windowId = windowId;
      box.__cardTitle = title;
      this.existingBoxes.push(box);

      box.onfocus = () => this.markWindowFocused(windowId, title);
      box.onminimize = () => this.markWindowMinimized(windowId, title);
      box.onmaximize = () => {
        (box as any).__isMaximized = true;
        this.applyMaximizedState(box);
      };
      box.onclose = () => {
        const index = this.existingBoxes.indexOf(box);
        if (index > -1) {
          this.existingBoxes.splice(index, 1);
        }
        this.windowEntries.update(entries => entries.filter(entry => entry.id !== windowId));
        return true;
      };

      this.windowEntries.update(entries => [
        ...entries.map(e => ({ ...e, focused: false })),
        {
          id: windowId,
          title: title,
          minimized: false,
          focused: true,
        },
      ]);

      setTimeout(() => {
        this.applyMaximizedState(box);
      }, 50);
    } catch {
      // Ignore errors
    }
  }

  private getAvailableViewport(): { left: number; top: number; width: number; height: number } {
    const windowHeight = typeof window !== 'undefined' ? window.innerHeight : 600;
    const windowWidth = typeof window !== 'undefined' ? window.innerWidth : 800;

    let topOffset = this.topCollapsed() ? 40 : 80;
    let bottomOffset = this.bottomCollapsed() ? 40 : 100;

    const availableHeight = windowHeight - topOffset - bottomOffset - 8;
    const availableWidth = windowWidth - 20;

    return {
      left: 10,
      top: topOffset + 4,
      width: availableWidth,
      height: Math.max(200, availableHeight),
    };
  }

  private applyMaximizedState(box: WinBoxInstance): void {
    setTimeout(() => {
      try {
        const viewport = this.getAvailableViewport();
        const isSqlite = box.__cardTitle?.includes('SQLite');
        const windowWidth = Math.min(500, viewport.width);
        const windowHeight = isSqlite ? Math.min(650, viewport.height) : Math.min(700, viewport.height);
        const x = viewport.left + (viewport.width - windowWidth) / 2;
        const y = viewport.top + (viewport.height - windowHeight) / 2;

        box.move(`${x}px`, `${y}px`);
        box.resize(`${windowWidth}px`, `${windowHeight}px`);
      } catch {
        // Ignore errors
      }
    }, 10);
  }

  activateWindow(windowId: string, event: Event): void {
    event.stopPropagation();
    const box = this.existingBoxes.find(box => box?.__windowId === windowId);
    if (!box) {
      this.windowEntries.update(entries => entries.filter(entry => entry.id !== windowId));
      return;
    }
    if (box.min) box.restore();
    box.focus();
    if ((box as any).__isMaximized) {
      this.applyMaximizedState(box);
    }
  }

  private markWindowFocused(windowId: string, title: string): void {
    this.windowEntries.update(entries =>
      entries.map(entry => ({
        ...entry,
        focused: entry.id === windowId,
        minimized: entry.id === windowId ? false : entry.minimized,
      }))
    );
  }

  private markWindowMinimized(windowId: string, title: string): void {
    this.windowEntries.update(entries =>
      entries.map(entry =>
        entry.id === windowId ? { ...entry, minimized: true, focused: false } : entry
      )
    );
  }

  private resizeAllWindows(): void {
    const viewport = this.getAvailableViewport();
    this.existingBoxes.forEach((box: any) => {
      if (box && !box.min) {
        try {
          const isSqlite = box.__cardTitle?.includes('SQLite');
          const windowWidth = Math.min(500, viewport.width);
          const windowHeight = isSqlite ? Math.min(650, viewport.height) : Math.min(700, viewport.height);
          const x = viewport.left + (viewport.width - windowWidth) / 2;
          const y = viewport.top + (viewport.height - windowHeight) / 2;

          box.move(`${x}px`, `${y}px`);
          box.resize(`${windowWidth}px`, `${windowHeight}px`);
        } catch {
          // Ignore errors
        }
      }
    });
  }
}
