# WebUI Integration Guide

## Overview

This project uses [v-webui](https://github.com/webui-dev/v-webui) to integrate the Angular frontend with the V backend. The `webui.js` library is dynamically served by the V backend and enables bidirectional communication between JavaScript and V code.

## How It Works

### Backend (V)

The V backend uses the v-webui library to:
1. Serve the Angular build files from `frontend/dist/browser`
2. Inject `webui.js` into HTML responses automatically
3. Bind V functions to JavaScript-callable handlers
4. Handle function calls from the frontend

Example V handler:
```v
window_mgr.bind('getUsers', fn [db] (e &ui.Event) string {
    users := db.get_all_users()
    return '{"success":true,"data":${json.encode(users)}}'
})
```

### Frontend (Angular)

The Angular frontend:
1. Loads `webui.js` from the server (injected by V backend)
2. Uses the `webui` global object to call V functions
3. Receives responses via custom events

Example Angular service:
```typescript
async call<T>(functionName: string, args: unknown[] = []): Promise<ApiResponse<T>> {
  return new Promise((resolve, reject) => {
    const handler = (event: CustomEvent<ApiResponse<T>>) => {
      resolve(event.detail);
    };
    window.addEventListener(`${functionName}_response`, handler as EventListener);
    const backendFn = (window as any)[functionName];
    backendFn(...args);
  });
}
```

## Build Process

### Automatic Patching (Production)

The production build automatically patches `index.html` to include `webui.js`:

1. **Rspack builds** the Angular application
2. **PatchWebUIPlugin** runs post-build
3. **patch-webui.js** injects the webui.js script tag
4. **Result**: `index.html` has webui.js loaded before Angular bundles

### Patch Script Location

- Script: `frontend/scripts/patch-webui.js`
- Runs automatically during production builds
- Can be run manually: `bun run patch:webui`

### Patched HTML Structure

```html
<!doctype html>
<html lang="en">
<head>
  <!-- ... meta tags ... -->
</head>
<body>
  <!-- WebUI Integration - Must load before Angular -->
  <script src="webui.js"></script>
  <script>
    // Wait for webui to be ready before Angular bootstraps
    window.webuiReady = new Promise((resolve) => {
      const checkWebUI = () => {
        if (typeof webui !== 'undefined') {
          console.log('[WebUI] Library loaded successfully');
          resolve();
        } else {
          setTimeout(checkWebUI, 10);
        }
      };
      checkWebUI();
    });
  </script>

  <app-root></app-root>
  <!-- Angular bundles loaded here -->
</body>
</html>
```

## Development vs Production

### Development Mode
- Rspack dev server runs independently
- webui.js is NOT automatically injected
- Use `bash run.sh dev` for integrated dev mode

### Production Mode
- Full build with webui.js injection
- V backend serves all static files
- webui.js is provided by the V backend at runtime

## Manual Patching

If you need to manually patch the HTML:

```bash
cd frontend
bun run patch:webui
```

## Troubleshooting

### webui is not defined

**Problem**: Angular tries to use webui before it's loaded

**Solution**: The patch script adds a readiness check. Use `window.webuiReady` promise:

```typescript
await window.webuiReady;
// Now safe to use webui functions
```

### Backend functions not found

**Problem**: `TypeError: backendFn is not a function`

**Solution**: Ensure the V backend has bound the function:
```v
window_mgr.bind('myFunction', fn [ctx] (e &ui.Event) string {
    // handler code
})
```

### Build fails after patching

**Problem**: HTML becomes malformed

**Solution**: Check that `index.html` has proper structure. The patch looks for `<body>` tag.

## File Locations

| File | Purpose |
|------|---------|
| `frontend/scripts/patch-webui.js` | Post-build patch script |
| `frontend/rspack.config.js` | Rspack config with PatchWebUIPlugin |
| `frontend/src/index.html` | Source HTML template |
| `frontend/dist/browser/index.html` | Patched production HTML |
| `thirdparty/v-webui/` | V WebUI library source |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    V Backend                            │
│  ┌─────────────────────────────────────────────────┐   │
│  │  v-webui library                                │   │
│  │  - Serves static files                          │   │
│  │  - Injects webui.js into HTML                   │   │
│  │  - Handles JS ↔ V communication                 │   │
│  └─────────────────────────────────────────────────┘   │
│                         ↕                               │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Application Handlers                           │   │
│  │  - getUsers()                                   │   │
│  │  - createProduct()                              │   │
│  │  - deleteOrder()                                │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                         ↕
                    webui.js
                         ↕
┌─────────────────────────────────────────────────────────┐
│                  Angular Frontend                       │
│  ┌─────────────────────────────────────────────────┐   │
│  │  ApiService                                     │   │
│  │  - call<T>(fn, args)                            │   │
│  │  - callOrThrow<T>(fn, args)                     │   │
│  └─────────────────────────────────────────────────┘   │
│                         ↕                               │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Components                                     │   │
│  │  - DashboardComponent                           │   │
│  │  - DuckdbUsersComponent                         │   │
│  │  - SqliteCrudComponent                          │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Best Practices

1. **Always use ApiService** - Don't call webui directly; use the abstraction layer
2. **Handle errors** - Wrap calls in try/catch
3. **Type responses** - Use TypeScript generics for type safety
4. **Loading states** - Show loading indicators during async operations
5. **Error boundaries** - Display user-friendly error messages

## References

- [v-webui Documentation](https://github.com/webui-dev/v-webui)
- [WebUI C Library](https://github.com/webui-dev/webui)
- [Angular Documentation](https://angular.dev)
