# Gemini Terminal Add-on: Interactive Session Picker - Development Status

## Project Overview
Implementing an interactive session picker feature for the Gemini Terminal Home Assistant add-on that allows users to choose how to launch Gemini (new session, continue, resume, custom command, or shell access).

## Current Status: 🟡 **90% Complete - Authentication Persistence Issue**

### ✅ **Completed Tasks**

#### Core Implementation
- ✅ **Session Picker Script** (`gemini-session-picker.sh`)
  - Interactive menu with 6 options (new, continue, resume, custom, shell, exit)
  - Proper error handling and user input validation
  - Clean UI with emojis and banner
  - All menu options functional

- ✅ **Configuration System** (`config.yaml`)
  - Added `auto_launch_gemini` boolean option (defaults to `true`)
  - Maintains backward compatibility
  - Version bumped to `1.1.0-dev`

- ✅ **Startup Logic** (`run.sh`)
  - Conditional launch based on configuration
  - Fallback mechanisms for missing components
  - Simplified credential management (removed complex system)

#### Testing & Validation
- ✅ **Static Analysis**: All shell scripts pass syntax validation
- ✅ **Container Build**: Successfully builds with Podman
- ✅ **Auto-launch Mode**: Backward compatibility confirmed
- ✅ **Session Picker**: Interactive menu works correctly
- ✅ **OAuth Authentication**: Gemini Code's native authentication flows work

#### Code Quality
- ✅ **Simplified Architecture**: Removed complex credential management system
- ✅ **Clean Implementation**: Let Gemini Code handle authentication natively
- ✅ **Proper Error Handling**: Graceful fallbacks and user feedback

### 🔴 **Critical Issue: Authentication Persistence**

**Problem**: Gemini Code's OAuth authentication doesn't persist across container restarts.

**Evidence**: 
- First run: OAuth works perfectly
- Container restart: Authentication lost, requires re-authentication

**Root Cause**: Unknown - need to investigate where Gemini Code actually stores OAuth tokens.

### 🎯 **Next Steps (Priority Order)**

#### 1. **CRITICAL: Investigate Gemini Code Credential Storage** (High Priority)
**Objective**: Determine where Gemini Code stores OAuth tokens after successful authentication.

**Investigation Commands**:
```bash
# After successful OAuth, run inside container:
find /root -name "*gemini*" -o -name "*google*" 2>/dev/null
find /config -name "*" -type f 2>/dev/null
find /root -name "*.json" -o -name ".*" -type f | head -20
ls -la /root/.config/
ls -la /root/
```

**Expected Locations**:
- `/root/.config/google/` (current assumption)
- `/root/.gemini*` files
- Browser-based storage locations
- Node.js application data directories

#### 2. **Implement Proper Persistence Solution** (High Priority)
**Options to Evaluate**:

**Option A: Enhanced Directory Mapping**
- Map additional directories that Gemini Code might use
- Investigate Node.js config directories, browser cache locations

**Option B: Minimal Credential Monitoring**
- Lightweight version of old system
- Only copy files that actually exist after OAuth
- No complex searching, just known locations

**Option C: Volume Mount Strategy**
- Mount entire `/root` directory (security implications)
- Mount specific subdirectories based on investigation results

#### 3. **Documentation & Release** (Medium Priority)
- Update `GEMINI.md` with new feature documentation
- Test authentication persistence solution
- Create proper commit for the feature
- Prepare for merge to main branch

### 🏗 **Implementation Details**

#### Files Modified
- `gemini-terminal/config.yaml` - Added configuration option
- `gemini-terminal/run.sh` - Simplified and added session picker logic
- `gemini-terminal/scripts/gemini-session-picker.sh` - New interactive menu
- Removed: `credentials-manager.sh`, `credentials-service.sh`, `gemini-auth.sh`

#### Architecture Decisions
- **Simplified Credential Management**: Removed complex background monitoring
- **Native Authentication**: Let Gemini Code handle OAuth directly
- **Backward Compatibility**: Default auto-launch preserves existing behavior
- **Clean Separation**: Session picker as separate script for modularity

### 🧪 **Testing Strategy**

#### Manual Testing Completed
1. ✅ Auto-launch mode (backward compatibility)
2. ✅ Session picker functionality
3. ✅ Container build and deployment
4. ✅ OAuth authentication flow

#### Testing Needed
1. 🔄 Authentication persistence across restarts
2. 🔄 All session picker options with real credentials
3. 🔄 Configuration changes in real Home Assistant environment

### 🚧 **Known Issues**
1. **Authentication Loss**: Primary blocker for release
2. **Local Testing Limitations**: `bashio::config` doesn't work in local containers
3. **Missing Real HA Testing**: Need to test in actual Home Assistant environment

### 🎯 **Success Criteria for Release**
- [ ] Authentication persists across container restarts
- [ ] Both auto-launch and session picker modes work reliably
- [ ] Documentation updated
- [ ] Backward compatibility maintained
- [ ] Professional-grade user experience

### 🔍 **Investigation Commands for Tomorrow**

```bash
# 1. Authenticate with Gemini and immediately check storage
podman exec -it $(podman ps -q) bash
# (after OAuth success)
find /root -type f -newer /etc/passwd 2>/dev/null | grep -v /proc | grep -v /sys
ls -laR /root/.config/

# 2. Test different environment variables
GEMINI_HOME=/config/gemini-config run-addon

# 3. Check Gemini Code documentation
gemini --help | grep -i config
gemini --help | grep -i auth
```

---

## Summary
The feature is 90% complete with excellent functionality, but authentication persistence is the critical blocker. The simplified architecture is much cleaner than the original complex credential management system. Once we solve the persistence issue, this will be ready for production deployment.