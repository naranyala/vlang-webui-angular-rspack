// Clipboard service for clipboard operations
import { Injectable } from '@angular/core';
import { getLogger } from '../viewmodels/logger.viewmodel';

export interface ClipboardResult {
  success: boolean;
  content?: string;
  error?: string;
}

@Injectable({ providedIn: 'root' })
export class ClipboardService {
  private readonly logger = getLogger('clipboard.service');

  /**
   * Copy text to clipboard
   */
  async copy(text: string): Promise<ClipboardResult> {
    try {
      // Try modern API first
      if (typeof navigator !== 'undefined' && navigator.clipboard) {
        await navigator.clipboard.writeText(text);
        this.logger.debug('Text copied to clipboard', { length: text.length });
        return { success: true, content: text };
      }

      // Fallback to execCommand
      const fallback = this.copyFallback(text);
      if (fallback.success) {
        this.logger.debug('Text copied using fallback', { length: text.length });
      }
      return fallback;
    } catch (error) {
      this.logger.error('Failed to copy to clipboard', { error });
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }

  /**
   * Paste text from clipboard
   */
  async paste(): Promise<ClipboardResult> {
    try {
      // Try modern API first
      if (typeof navigator !== 'undefined' && navigator.clipboard) {
        const text = await navigator.clipboard.readText();
        this.logger.debug('Text pasted from clipboard', { length: text.length });
        return { success: true, content: text };
      }

      return {
        success: false,
        error: 'Clipboard API not available',
      };
    } catch (error) {
      this.logger.error('Failed to paste from clipboard', { error });
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }

  /**
   * Check if clipboard API is available
   */
  isAvailable(): boolean {
    return typeof navigator !== 'undefined' && !!navigator.clipboard;
  }

  /**
   * Check if clipboard read permission is granted
   */
  async hasReadPermission(): Promise<boolean> {
    try {
      if (typeof navigator === 'undefined' || !navigator.permissions) {
        return false;
      }

      const result = await navigator.permissions.query({ name: 'clipboard-read' as PermissionName });
      return result.state === 'granted';
    } catch {
      return false;
    }
  }

  /**
   * Fallback copy using execCommand (for older browsers)
   */
  private copyFallback(text: string): ClipboardResult {
    try {
      if (typeof document === 'undefined') {
        return { success: false, error: 'Document not available' };
      }

      const textArea = document.createElement('textarea');
      textArea.value = text;
      textArea.style.position = 'fixed';
      textArea.style.top = '0';
      textArea.style.left = '0';
      textArea.style.width = '2em';
      textArea.style.height = '2em';
      textArea.style.padding = '0';
      textArea.style.border = 'none';
      textArea.style.outline = 'none';
      textArea.style.boxShadow = 'none';
      textArea.style.background = 'transparent';
      textArea.style.opacity = '0';

      document.body.appendChild(textArea);
      textArea.focus();
      textArea.select();

      const successful = document.execCommand('copy');
      document.body.removeChild(textArea);

      if (successful) {
        return { success: true, content: text };
      } else {
        return { success: false, error: 'execCommand failed' };
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Fallback failed',
      };
    }
  }
}
