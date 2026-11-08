(function(window) {
  'use strict';

  const translations = {
    vi: {
      // General & Common
      'app_title': 'Dylix Remote',
      'local_network': 'MẠNG CỤC BỘ (LAN)',
      'connecting': 'Đang kết nối',
      'connected': 'Đã kết nối',
      'reconnecting': 'Đang kết nối lại',
      'disconnected': 'Mất kết nối',
      'reading_device_state': 'Đang đọc trạng thái thiết bị',
      'check_network_or_dylix': 'Kiểm tra mạng hoặc quay lại Dylix trên điện thoại',
      'connecting_to_phone': 'Đang kết nối với điện thoại',
      'served_by_device': 'Cung cấp bởi iPhone / iPad của bạn',
      'collapse_nav': 'Thu gọn điều hướng',
      'expand_nav': 'Mở rộng điều hướng',
      'workspace_nav': 'Điều hướng bàn làm việc',
      'workspace_title': 'Không gian làm việc',
      'remote_workspace': 'Bàn làm việc từ xa',
      'overview': 'Tổng quan',
      'select_project': 'Chọn dự án',
      'toggle_theme': 'Chuyển chế độ sáng/tối',
      'disconnect': 'Ngắt kết nối',
      'refresh_status': 'Làm mới trạng thái',
      'your_local_workspace': 'Bàn làm việc cục bộ của bạn.',
      'realtime_status_desc': 'Trạng thái thời gian thực từ thiết bị, dữ liệu và thực thi luôn lưu trên điện thoại.',
      'current_task': 'Tác vụ hiện tại',
      'request_cancel': 'Yêu cầu hủy',
      'syncing': 'Đang đồng bộ',
      'data_on_device': 'Dữ liệu & Thực thi · Tại thiết bị',
      'cancel': 'Hủy',
      'confirm': 'Xác nhận',
      'execute': 'Thực hiện',
      'please_confirm_action': 'Vui lòng kiểm tra thao tác',
      'execute_this_action': 'Thực hiện thao tác này?',
      'copy': 'Sao chép',
      'copied': 'Đã sao chép',
      'delete': 'Xóa',
      'edit': 'Chỉnh sửa',
      'save': 'Lưu',
      'saved': 'Đã lưu',
      'download': 'Tải xuống',
      'upload': 'Tải lên',
      'language': 'Ngôn ngữ',

      // Pairing Page
      'from_phone_to_desktop': 'Từ điện thoại, mở rộng lên máy tính.',
      'workspace_new_screen_h1': 'Đổi màn hình làm việc.<br><em>Thực thi vẫn trên thiết bị.</em>',
      'pair_instruction': 'Kết nối cùng mạng Wi-Fi, bật "Điều khiển qua LAN" trên iPhone hoặc iPad để ghép đôi với trình duyệt.',
      'your_device_your_workspace': 'Thiết bị của bạn · Bàn làm việc của bạn',
      'build_connection_step': 'THIẾT LẬP KẾT NỐI / 01',
      'pair_with_dylix': 'Ghép đôi với Dylix',
      'name_this_browser': 'Đặt tên cho trình duyệt này',
      'name_placeholder': 'Ví dụ: MacBook của tôi',
      'code_label': 'Mã xác thực hiển thị trên điện thoại',
      'request_permissions': 'Yêu cầu quyền đọc/ghi dự án, xây dựng, Git và AI',
      'connect_button': 'Yêu cầu kết nối',
      'pair_tip': 'Nhập đúng mã ủy quyền để kết nối ngay, không cần xác nhận lại trên điện thoại.',
      'security_note': 'Bàn làm việc và WebDAV đều dùng HTTP. Các thao tác ghi và Git vẫn cần xác nhận trước khi thực hiện.',
      'footer_tagline': 'Thực thi trên điện thoại. Kiểm soát trên trình duyệt.',
      'waiting_to_pair': 'Chờ ghép đôi',

      // Modules
      'mod_overview': 'Tổng quan',
      'mod_overview_desc': '',
      'mod_projects': 'Quản lý dự án',
      'mod_projects_desc': 'Truy cập danh sách dự án hiện có, mẫu và dịch vụ nhập tệp.',
      'mod_files': 'Quản lý tệp',
      'mod_files_desc': 'Duyệt thư mục tài liệu Dylix, dự án và sản phẩm dựng; tải lên, xem trước hoặc tải xuống.',
      'mod_editor': 'Trình biên tập trực tuyến',
      'mod_editor_desc': 'Trình biên tập Monaco ngoại tuyến, nhiều tab & Diff, lưu trực tiếp vào dự án thực tế.',
      'mod_builds': 'Trung tâm xây dựng',
      'mod_builds_desc': 'Gọi Clang / LLD nội bộ của thiết bị, bảo vệ đơn tác vụ, nhật ký và sản phẩm.',
      'mod_git': 'Quản lý Git',
      'mod_git_desc': 'Tái sử dụng libgit2 với quyền gốc, xác nhận trước khi commit và đồng bộ từ xa.',
      'mod_ai': 'Trợ lý AI',
      'mod_ai_desc': 'Sử dụng mô hình đã cấu hình với các phiên trò chuyện, công cụ và duyệt đề xuất.',
      'mod_binary': 'Phân tích nhị phân',
      'mod_binary_desc': 'Thực hiện phân tích IPA / Mach-O và xuất tệp tiêu đề trên điện thoại.',
      'mod_webdav': 'WebDAV',
      'mod_webdav_desc': 'Cổng riêng biệt, phân quyền thư mục rõ ràng và phương thức WebDAV tiêu chuẩn.',
      'mod_tasks': 'Trung tâm tác vụ',
      'mod_tasks_desc': 'Theo dõi tập trung các tác vụ xây dựng, Git, phân tích và xuất dữ liệu.',
      'mod_settings': 'Cài đặt kết nối',
      'mod_settings_desc': 'Ủy quyền hiện tại chỉ gồm thông tin thiết bị. Cổng và mã ủy quyền cài đặt trong Dylix.',

      // Overview
      'local_service_online': 'Dịch vụ thiết bị đang trực tuyến',
      'permission_readonly': 'Quyền · Chỉ xem tổng quan thiết bị',
      'permission_full': 'Quyền · Toàn quyền bàn làm việc',
      'build_engine': 'Động cơ xây dựng',
      'build_engine_sub': 'Dùng động cơ có sẵn trên Dylix',
      'default_sdk': 'SDK mặc định',
      'available_sdk': 'SDK khả dụng',
      'available_sdk_sub': 'Đầu vào biên dịch nhúng trong máy',
      'connection_and_activity': 'Kết nối & Hoạt động',
      'current_session': 'Phiên hiện tại',
      'device_details': 'Chi tiết thiết bị',
      'device_details_note': 'Kết nối qua HTTP. Khi chuyển về Dylix dịch vụ sẽ tiếp tục mà không cần ủy quyền lại.',

      // Events
      'evt_server_running': 'Máy chủ HTTP đã khởi động',
      'evt_server_stopped': 'Máy chủ HTTP đã dừng',
      'evt_server_failed': 'Lắng nghe HTTP thất bại',
      'evt_pair_requested': 'Thiết bị mới yêu cầu ghép đôi',
      'evt_pair_approved': 'Thiết bị đã được cấp quyền',
      'evt_pair_approved_direct': 'Mã ủy quyền hợp lệ',
      'evt_pair_denied': 'Điện thoại từ chối yêu cầu thiết bị',
      'evt_device_revoked': 'Ủy quyền thiết bị đã bị thu hồi',
      'evt_all_devices_revoked': 'Đã ngắt toàn bộ thiết bị',
      'evt_network_changed': 'Mạng thay đổi, dịch vụ dừng'
    },
    zh: {
      'app_title': 'Dylix Remote',
      'local_network': 'LOCAL NETWORK',
      'connecting': '正在连接',
      'connected': '已连接',
      'reconnecting': '正在重连',
      'disconnected': '连接中断',
      'reading_device_state': '正在读取设备状态',
      'check_network_or_dylix': '检查网络或返回手机 Dylix',
      'connecting_to_phone': '正在与手机建立连接',
      'served_by_device': '由你的 iPhone / iPad 提供服务',
      'collapse_nav': '收起导航',
      'expand_nav': '展开导航',
      'workspace_nav': '工作台导航',
      'workspace_title': '工作空间',
      'remote_workspace': '远程工作台',
      'overview': '总览',
      'select_project': '选择项目',
      'toggle_theme': '切换深色或浅色',
      'disconnect': '断开连接',
      'refresh_status': '刷新状态',
      'your_local_workspace': '你的本机工作台。',
      'realtime_status_desc': '来自设备的实时状态，执行与数据始终留在手机。',
      'current_task': '当前任务',
      'request_cancel': '请求取消',
      'syncing': '正在同步',
      'data_on_device': '数据与执行 · 位于设备',
      'cancel': '取消',
      'confirm': '确认',
      'execute': '执行',
      'please_confirm_action': '请核对操作',
      'execute_this_action': '执行此操作？',
      'copy': '复制',
      'copied': '已复制',
      'delete': '删除',
      'edit': '编辑',
      'save': '保存',
      'saved': '已保存',
      'download': '下载',
      'upload': '上传',
      'language': '语言',

      // Pairing Page
      'from_phone_to_desktop': '从手机，延伸到桌面。',
      'workspace_new_screen_h1': '工作台换个屏幕。<br><em>执行，留在本机。</em>',
      'pair_instruction': '连接同一 Wi-Fi，在 iPhone 或 iPad 上开启「局域网远程」，与当前浏览器配对。',
      'your_device_your_workspace': '你的设备 · 你的工作台',
      'build_connection_step': '建立连接 / 01',
      'pair_with_dylix': '与 Dylix 配对',
      'name_this_browser': '为这个浏览器命名',
      'name_placeholder': '例如：我的 MacBook',
      'code_label': '手机显示的授权码',
      'request_permissions': '申请项目读写、构建、Git 与 AI 权限',
      'connect_button': '请求连接',
      'pair_tip': '输入正确授权码即可连接，无需手机再次确认。',
      'security_note': '工作台与 WebDAV 均使用 HTTP。写入和 Git 操作仍展示操作确认。',
      'footer_tagline': '在手机执行。在浏览器掌控。',
      'waiting_to_pair': '等待配对',

      // Modules
      'mod_overview': '总览',
      'mod_overview_desc': '',
      'mod_projects': '项目管理',
      'mod_projects_desc': '接入现有项目列表、模板与导入服务，沿用手机上的项目身份与目录。',
      'mod_files': '文件管理',
      'mod_files_desc': '浏览 Dylix 文稿目录、项目与构建产物，逐层打开文件夹，上传、预览或下载文件。',
      'mod_editor': '在线编辑器',
      'mod_editor_desc': '离线 Monaco 编辑器、多标签与 Diff，保存到手机真实项目，保留双方编辑冲突。',
      'mod_builds': '构建中心',
      'mod_builds_desc': '调用设备已有 Clang / LLD 构建入口，共用单任务保护、日志与产物。',
      'mod_git': 'Git 管理',
      'mod_git_desc': '复用 libgit2 与原生权限、写租约和冲突指纹，确认后执行提交与远程同步。',
      'mod_ai': 'AI 助手',
      'mod_ai_desc': '使用 Dylix 已配置模型与同一套会话、工具、提案确认，不向浏览器传送模型密钥。',
      'mod_binary': '二进制分析',
      'mod_binary_desc': '在手机执行 IPA / Mach-O 分析与头文件导出，支持任务进度、取消和结果下载。',
      'mod_webdav': 'WebDAV',
      'mod_webdav_desc': '独立端口、明确目录授权与标准 WebDAV 方法；挂载兼容性逐平台验证。',
      'mod_tasks': '任务中心',
      'mod_tasks_desc': '统一观察构建、Git、分析和导出任务，显示真实进度和实际可取消边界。',
      'mod_settings': '连接设置',
      'mod_settings_desc': '当前授权仅包含只读设备概况。端口、配对码、设备撤权和停止服务请在手机「局域网远程」中设置。',

      // Overview
      'local_service_online': '本机服务在线',
      'permission_readonly': '权限 · 只读设备概况',
      'permission_full': '权限 · 工作空间完整访问',
      'build_engine': '构建引擎',
      'build_engine_sub': '使用 Dylix 已有本机引擎',
      'default_sdk': '默认 SDK',
      'available_sdk': '可用 SDK',
      'available_sdk_sub': '设备内嵌的编译输入',
      'connection_and_activity': '连接与活动',
      'current_session': '本次服务',
      'device_details': '设备详情',
      'device_details_note': '连接使用 HTTP。后台先争取传输时间，系统挂起后返回 App 会恢复服务，无需重新授权。锁屏时受保护文件需要解锁。',

      // Events
      'evt_server_running': 'HTTP 服务已启动',
      'evt_server_stopped': 'HTTP 服务已停止',
      'evt_server_failed': 'HTTP 监听失败',
      'evt_pair_requested': '新设备申请配对',
      'evt_pair_approved': '设备已授权',
      'evt_pair_approved_direct': '授权码验证通过',
      'evt_pair_denied': '手机拒绝设备申请',
      'evt_device_revoked': '设备授权已撤销',
      'evt_all_devices_revoked': '全部设备已断开',
      'evt_network_changed': '网络变化，服务停止'
    },
    en: {
      'app_title': 'Dylix Remote',
      'local_network': 'LOCAL NETWORK',
      'connecting': 'Connecting',
      'connected': 'Connected',
      'reconnecting': 'Reconnecting',
      'disconnected': 'Disconnected',
      'reading_device_state': 'Reading device status',
      'check_network_or_dylix': 'Check network or return to Dylix on device',
      'connecting_to_phone': 'Connecting to device',
      'served_by_device': 'Served by your iPhone / iPad',
      'collapse_nav': 'Collapse navigation',
      'expand_nav': 'Expand navigation',
      'workspace_nav': 'Workspace navigation',
      'workspace_title': 'Workspace',
      'remote_workspace': 'Remote Workspace',
      'overview': 'Overview',
      'select_project': 'Select Project',
      'toggle_theme': 'Toggle Dark / Light mode',
      'disconnect': 'Disconnect',
      'refresh_status': 'Refresh status',
      'your_local_workspace': 'Your Local Workspace.',
      'realtime_status_desc': 'Live status from your device. Execution and data stay on your phone.',
      'current_task': 'Current Task',
      'request_cancel': 'Request Cancel',
      'syncing': 'Syncing',
      'data_on_device': 'Data & Execution · On Device',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'execute': 'Execute',
      'please_confirm_action': 'Please verify action',
      'execute_this_action': 'Execute this action?',
      'copy': 'Copy',
      'copied': 'Copied',
      'delete': 'Delete',
      'edit': 'Edit',
      'save': 'Save',
      'saved': 'Saved',
      'download': 'Download',
      'upload': 'Upload',
      'language': 'Language',

      // Pairing Page
      'from_phone_to_desktop': 'Extending from phone to desktop.',
      'workspace_new_screen_h1': 'A bigger screen for your workspace.<br><em>Execution stays local.</em>',
      'pair_instruction': 'Connect to the same Wi-Fi, enable "LAN Remote" on iPhone or iPad, and pair with this browser.',
      'your_device_your_workspace': 'Your Device · Your Workspace',
      'build_connection_step': 'CONNECT / 01',
      'pair_with_dylix': 'Pair with Dylix',
      'name_this_browser': 'Name this browser',
      'name_placeholder': 'e.g. My MacBook',
      'code_label': 'Passcode shown on device',
      'request_permissions': 'Request project read/write, build, Git, and AI permissions',
      'connect_button': 'Request Connection',
      'pair_tip': 'Enter the correct passcode to connect directly without re-confirming on device.',
      'security_note': 'Workspace and WebDAV use HTTP. Write and Git operations require confirmation.',
      'footer_tagline': 'Executed on device. Controlled in browser.',
      'waiting_to_pair': 'Waiting for pairing',

      // Modules
      'mod_overview': 'Overview',
      'mod_overview_desc': '',
      'mod_projects': 'Projects',
      'mod_projects_desc': 'Access project list, templates, and import services on device.',
      'mod_files': 'Files',
      'mod_files_desc': 'Browse Dylix documents, projects, and build artifacts; upload, preview, or download files.',
      'mod_editor': 'Online Editor',
      'mod_editor_desc': 'Offline Monaco editor with tabs and diffs, saving directly to project files.',
      'mod_builds': 'Build Center',
      'mod_builds_desc': 'Invoke Clang / LLD on device with single-task protection, logs, and artifacts.',
      'mod_git': 'Git Management',
      'mod_git_desc': 'Reuse libgit2 with native permissions and leases for commits and remote sync.',
      'mod_ai': 'AI Assistant',
      'mod_ai_desc': 'Use configured models with conversations, tools, and proposal reviews.',
      'mod_binary': 'Binary Analysis',
      'mod_binary_desc': 'Run IPA / Mach-O analysis and export headers on device.',
      'mod_webdav': 'WebDAV',
      'mod_webdav_desc': 'Dedicated port, clear authorization, and standard WebDAV protocol.',
      'mod_tasks': 'Task Center',
      'mod_tasks_desc': 'Unified view of build, Git, analysis, and export tasks with cancel support.',
      'mod_settings': 'Connection Settings',
      'mod_settings_desc': 'Read-only device overview. Ports and passcodes are configured in Dylix app.',

      // Overview
      'local_service_online': 'Local service online',
      'permission_readonly': 'Permission · Read-only device overview',
      'permission_full': 'Permission · Full workspace access',
      'build_engine': 'Build Engine',
      'build_engine_sub': 'Using Dylix embedded local engine',
      'default_sdk': 'Default SDK',
      'available_sdk': 'Available SDKs',
      'available_sdk_sub': 'Built-in compiler inputs on device',
      'connection_and_activity': 'Connections & Activity',
      'current_session': 'Current Session',
      'device_details': 'Device Details',
      'device_details_note': 'Uses HTTP. Reopening Dylix restores connection without re-authorizing.',

      // Events
      'evt_server_running': 'HTTP service started',
      'evt_server_stopped': 'HTTP service stopped',
      'evt_server_failed': 'HTTP listening failed',
      'evt_pair_requested': 'New device requested pairing',
      'evt_pair_approved': 'Device authorized',
      'evt_pair_approved_direct': 'Passcode verified',
      'evt_pair_denied': 'Device request rejected',
      'evt_device_revoked': 'Device authorization revoked',
      'evt_all_devices_revoked': 'All devices disconnected',
      'evt_network_changed': 'Network changed, service stopped'
    }
  };

  function detectLanguage() {
    let saved = '';
    try {
      saved = localStorage.getItem('DylixRemoteLang');
    } catch (e) {}
    if (saved && translations[saved]) return saved;
    const navLang = (navigator.language || navigator.userLanguage || '').toLowerCase();
    if (navLang.startsWith('vi')) return 'vi';
    if (navLang.startsWith('zh')) return 'zh';
    if (navLang.startsWith('en')) return 'en';
    return 'vi'; // Default to Vietnamese per user request!
  }

  const i18n = {
    lang: detectLanguage(),
    translations: translations,

    t(key) {
      const dict = translations[this.lang] || translations.vi;
      return dict[key] !== undefined ? dict[key] : (translations.zh[key] || key);
    },

    setLang(lang) {
      if (!translations[lang]) return;
      this.lang = lang;
      try {
        localStorage.setItem('DylixRemoteLang', lang);
      } catch (e) {}
      document.documentElement.lang = lang === 'zh' ? 'zh-CN' : lang;
      this.updateDOM();
      if (typeof window.onDylixLanguageChange === 'function') {
        window.onDylixLanguageChange(lang);
      }
    },

    updateDOM() {
      document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.dataset.i18n;
        const val = this.t(key);
        if (el.dataset.i18nHtml) {
          el.innerHTML = val;
        } else {
          el.textContent = val;
        }
      });
      document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
        el.placeholder = this.t(el.dataset.i18nPlaceholder);
      });
      document.querySelectorAll('[data-i18n-title]').forEach(el => {
        el.title = this.t(el.dataset.i18nTitle);
      });
      document.querySelectorAll('[data-i18n-aria]').forEach(el => {
        el.setAttribute('aria-label', this.t(el.dataset.i18nAria));
      });
    }
  };

  window.i18n = i18n;
  window.t = function(key) { return i18n.t(key); };
})(window);
