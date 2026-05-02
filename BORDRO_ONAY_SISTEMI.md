# Güvenli Bordro Onay Sistemi

## Genel Bakış

Bordro onay sistemi, çalışanların bordrolarını güvenli ve yasal olarak onaylamalarını sağlayan entegre bir çözümdür. Sistem, 3 farklı doğrulama yöntemi sunarak kullanıcılara esneklik sağlar.

## Doğrulama Yöntemleri

### 1. Dijital İmza
- **Açıklama:** Kullanıcılar ekran üzerinde imza atarak bordroyu onaylar
- **Kullanım:** Fare veya dokunmatik ekran ile canvas üzerinde imza çizilir
- **Güvenlik:** İmza verisi base64 formatında şifrelenerek saklanır
- **Avantajlar:** Hızlı, kolay ve kişiselleştirilmiş

### 2. Kimlik Belgesi
- **Açıklama:** Kullanıcılar kimlik kartı veya ehliyet fotoğrafı yükler
- **Desteklenen Formatlar:** PNG, JPG, JPEG
- **Maksimum Boyut:** 10MB
- **Güvenlik:** Görsel verisi şifrelenerek veritabanında saklanır
- **Avantajlar:** Yüksek güvenlik, doğrulama kanıtı

### 3. Şifre Doğrulama
- **Açıklama:** Her çalışana özel tanımlanan şifre ile onay
- **Şifre Tanımlama:** Personel düzenleme ekranından yapılır
- **Güvenlik:** Şifre hash'lenerek saklanır
- **Avantajlar:** Hızlı, pratik, güvenli

## Güvenlik Özellikleri

### Zaman Damgası
- Her onay işlemi ISO 8601 formatında zaman damgası ile kaydedilir
- Zaman damgası değiştirilemez ve denetlenebilir

### IP Adresi Kaydı
- Onay yapılan IP adresi otomatik olarak kaydedilir
- Coğrafi konum takibi için kullanılabilir

### Tarayıcı Bilgisi
- User-Agent bilgisi kaydedilir
- Hangi cihaz ve tarayıcıdan onay verildiği takip edilir

### 256-bit <!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rol Tabanlı Yetkilendirme Sistemi</title>
    <!-- Font Awesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', sans-serif;
            background: #f0f2f5;
            height: 100vh;
            overflow: hidden;
        }

        /* Login Screen Styles */
        .login-container {
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }

        .login-box {
            background: white;
            padding: 40px;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            width: 100%;
            max-width: 400px;
            animation: slideUp 0.5s ease;
        }

        @keyframes slideUp {
            from {
                opacity: 0;
                transform: translateY(20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .login-header {
            text-align: center;
            margin-bottom: 30px;
        }

        .login-header h2 {
            color: #333;
            font-size: 28px;
            font-weight: 600;
            margin-bottom: 10px;
        }

        .login-header p {
            color: #666;
            font-size: 14px;
        }

        .role-badge {
            display: inline-block;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            margin: 5px;
            cursor: pointer;
            transition: all 0.3s ease;
        }

        .role-badge.super-admin {
            background: #ff4757;
            color: white;
        }

        .role-badge.company-admin {
            background: #4834d4;
            color: white;
        }

        .role-badge.manager {
            background: #00b894;
            color: white;
        }

        .role-badge.employee {
            background: #f39c12;
            color: white;
        }

        .role-badge:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.2);
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: #555;
            font-weight: 500;
            font-size: 14px;
        }

        .form-group input {
            width: 100%;
            padding: 12px 16px;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            font-size: 14px;
            transition: all 0.3s ease;
        }

        .form-group input:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }

        .login-btn {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
        }

        .login-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3);
        }

        /* Dashboard Styles */
        .dashboard-container {
            display: flex;
            height: 100vh;
            opacity: 0;
            transition: opacity 0.3s ease;
        }

        .dashboard-container.active {
            opacity: 1;
        }

        /* Sidebar */
        .sidebar {
            width: 280px;
            background: white;
            box-shadow: 2px 0 10px rgba(0, 0, 0, 0.05);
            display: flex;
            flex-direction: column;
            transition: all 0.3s ease;
        }

        .sidebar-header {
            padding: 25px 20px;
            border-bottom: 1px solid #f0f0f0;
        }

        .sidebar-header h3 {
            color: #333;
            font-size: 20px;
            font-weight: 600;
        }

        .sidebar-header p {
            color: #666;
            font-size: 13px;
            margin-top: 5px;
        }

        .user-info {
            padding: 20px;
            background: #f8f9fa;
            margin: 15px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .user-avatar {
            width: 50px;
            height: 50px;
            border-radius: 12px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 20px;
            font-weight: 600;
        }

        .user-details h4 {
            color: #333;
            font-size: 15px;
            font-weight: 600;
            margin-bottom: 4px;
        }

        .user-details span {
            color: #667eea;
            font-size: 12px;
            font-weight: 500;
            background: rgba(102, 126, 234, 0.1);
            padding: 4px 8px;
            border-radius: 20px;
        }

        .sidebar-menu {
            flex: 1;
            padding: 20px;
            overflow-y: auto;
        }

        .menu-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 15px;
            color: #666;
            border-radius: 10px;
            margin-bottom: 5px;
            transition: all 0.3s ease;
            cursor: pointer;
        }

        .menu-item:hover {
            background: #f8f9fa;
            color: #667eea;
        }

        .menu-item.active {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }

        .menu-item i {
            width: 20px;
            font-size: 18px;
        }

        .contract-warning {
            margin: 15px;
            padding: 15px;
            background: #fff3cd;
            border: 1px solid #ffeeba;
            border-radius: 10px;
            color: #856404;
            font-size: 13px;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .contract-warning i {
            font-size: 20px;
            color: #856404;
        }

        /* Main Content */
        .main-content {
            flex: 1;
            background: #f8f9fa;
            overflow-y: auto;
            padding: 25px;
        }

        .top-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
            background: white;
            padding: 15px 25px;
            border-radius: 12px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.02);
        }

        .page-title h2 {
            color: #333;
            font-size: 22px;
            font-weight: 600;
        }

        .top-bar-actions {
            display: flex;
            align-items: center;
            gap: 15px;
        }

        .logout-btn {
            padding: 10px 20px;
            background: #ff4757;
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .logout-btn:hover {
            background: #ff3838;
            transform: translateY(-2px);
        }

        /* Content Cards */
        .content-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 25px;
            margin-bottom: 25px;
        }

        .card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.02);
            transition: all 0.3s ease;
        }

        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
        }

        .card-header {
            display: flex;
            align-items: center;
            gap: 15px;
            margin-bottom: 20px;
        }

        .card-icon {
            width: 50px;
            height: 50px;
            border-radius: 12px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 20px;
        }

        .card-title h3 {
            color: #333;
            font-size: 16px;
            font-weight: 600;
            margin-bottom: 5px;
        }

        .card-title p {
            color: #666;
            font-size: 13px;
        }

        /* Tables */
        .table-container {
            background: white;
            border-radius: 15px;
            padding: 25px;
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th {
            text-align: left;
            padding: 15px;
            color: #666;
            font-weight: 600;
            font-size: 13px;
            border-bottom: 2px solid #f0f0f0;
        }

        td {
            padding: 15px;
            color: #333;
            font-size: 14px;
            border-bottom: 1px solid #f0f0f0;
        }

        .status-badge {
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 500;
        }

        .status-badge.approved {
            background: #d4edda;
            color: #155724;
        }

        .status-badge.pending {
            background: #fff3cd;
            color: #856404;
        }

        .status-badge.rejected {
            background: #f8d7da;
            color: #721c24;
        }

        .action-btn {
            padding: 6px 12px;
            border: none;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.3s ease;
            margin: 0 3px;
        }

        .action-btn.approve {
            background: #d4edda;
            color: #155724;
        }

        .action-btn.reject {
            background: #f8d7da;
            color: #721c24;
        }

        .action-btn:hover {
            transform: translateY(-2px);
            filter: brightness(0.95);
        }

        /* Contract Modal */
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            justify-content: center;
            align-items: center;
            z-index: 1000;
        }

        .modal.active {
            display: flex;
        }

        .modal-content {
            background: white;
            border-radius: 20px;
            width: 90%;
            max-width: 600px;
            max-height: 80vh;
            overflow-y: auto;
            animation: slideUp 0.3s ease;
        }

        .modal-header {
            padding: 25px;
            border-bottom: 1px solid #f0f0f0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .modal-header h3 {
            color: #333;
            font-size: 20px;
            font-weight: 600;
        }

        .close-btn {
            background: none;
            border: none;
            font-size: 24px;
            cursor: pointer;
            color: #666;
        }

        .modal-body {
            padding: 25px;
        }

        .contract-text {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            font-size: 14px;
            line-height: 1.6;
            color: #333;
            max-height: 300px;
            overflow-y: auto;
        }

        .payment-info {
            background: #e3f2fd;
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }

        .payment-info p {
            margin: 10px 0;
            color: #0d47a1;
        }

        .checkbox-label {
            display: flex;
            align-items: center;
            gap: 10px;
            margin: 20px 0;
            cursor: pointer;
        }

        .approve-contract-btn {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
        }

        .approve-contract-btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }

        /* Responsive */
        @media (max-width: 768px) {
            .sidebar {
                position: fixed;
                left: -280px;
                top: 0;
                bottom: 0;
                z-index: 100;
            }

            .sidebar.active {
                left: 0;
            }

            .content-cards {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <!-- Login Screen -->
    <div id="loginScreen" class="login-container">
        <div class="login-box">
            <div class="login-header">
                <h2>Hoş Geldiniz</h2>
                <p>Test hesapları ile giriş yapabilirsiniz</p>
                <div style="margin-top: 15px;">
                    <span class="role-badge super-admin" onclick="fillLogin('super@admin.com')">Süper Admin</span>
                    <span class="role-badge company-admin" onclick="fillLogin('company@admin.com')">Şirket Admin</span>
                    <span class="role-badge manager" onclick="fillLogin('manager@company.com')">Departman Müdürü</span>
                    <span class="role-badge employee" onclick="fillLogin('employee@company.com')">Personel</span>
                </div>
            </div>
            
            <div class="form-group">
                <label>E-posta</label>
                <input type="email" id="email" placeholder="ornek@email.com" value="super@admin.com">
            </div>
            
            <div class="form-group">
                <label>Şifre</label>
                <input type="password" id="password" placeholder="••••••••" value="123456">
            </div>
            
            <button class="login-btn" onclick="login()">
                <i class="fas fa-sign-in-alt" style="margin-right: 8px;"></i>
                Giriş Yap
            </button>
        </div>
    </div>

    <!-- Dashboard -->
    <div id="dashboard" class="dashboard-container">
        <!-- Sidebar -->
        <div class="sidebar" id="sidebar">
            <div class="sidebar-header">
                <h3>Şirket Yönetim Sistemi</h3>
                <p>Rol tabanlı yetkilendirme</p>
            </div>
            
            <div class="user-info" id="userInfo">
                <!-- Dynamic user info will be inserted here -->
            </div>
            
            <!-- Contract Warning (gösterilecekse) -->
            <div id="contractWarning" class="contract-warning" style="display: none;">
                <i class="fas fa-exclamation-triangle"></i>
                <div>
                    <strong>Sözleşme onayı bekliyor!</strong>
                    <p style="margin-top: 5px;">Sistemi kullanmak için sözleşmeyi onaylamalısınız.</p>
                </div>
            </div>
            
            <div class="sidebar-menu" id="sidebarMenu">
                <!-- Dynamic menu will be inserted here -->
            </div>
        </div>
        
        <!-- Main Content -->
        <div class="main-content">
            <div class="top-bar">
                <div class="page-title">
                    <h2 id="pageTitle">Dashboard</h2>
                </div>
                <div class="top-bar-actions">
                    <button class="logout-btn" onclick="logout()">
                        <i class="fas fa-sign-out-alt"></i>
                        Çıkış Yap
                    </button>
                </div>
            </div>
            
            <div id="contentArea">
                <!-- Dynamic content will be inserted here -->
            </div>
        </div>
    </div>

    <!-- Contract Modal -->
    <div id="contractModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h3>Kullanıcı Sözleşmesi</h3>
                <button class="close-btn" onclick="closeContractModal()">&times;</button>
            </div>
            <div class="modal-body">
                <div class="contract-text">
                    <h4>KULLANICI SÖZLEŞMESİ</h4>
                    <p style="margin-top: 15px;">1. Taraflar: Bu sözleşme, [Şirket Adı] ile sistem kullanıcısı arasında düzenlenmiştir.</p>
                    <p>2. Kapsam: Bu sözleşme, kullanıcının sistemi kullanım şartlarını düzenler.</p>
                    <p>3. Gizlilik: Kullanıcı, şirket bilgilerinin gizliliğini korumayı kabul eder.</p>
                    <p>4. Sorumluluk: Kullanıcı, hesap hareketlerinden kendisi sorumludur.</p>
                    <p>5. Ödeme: Sistem kullanım bedeli, her ayın ilk haftasında tahsil edilir.</p>
                    <p>6. Fesih: Taraflar, 30 gün önceden bildirimde bulunarak sözleşmeyi feshedebilir.</p>
                    <p style="margin-top: 15px;">Son güncelleme: 15 Mart 2024</p>
                </div>
                
                <div class="payment-info">
                    <p><i class="fas fa-university"></i> <strong>Banka:</strong> Örnek Bankası A.Ş.</p>
                    <p><i class="fas fa-credit-card"></i> <strong>IBAN:</strong> TR12 3456 7890 1234 5678 9012</p>
                    <p><i class="fas fa-user"></i> <strong>Alıcı Adı:</strong> Örnek Şirket</p>
                    <p><i class="fas fa-info-circle"></i> <strong>Açıklama:</strong> Kullanıcı ID'nizi açıklamaya yazınız.</p>
                </div>
                
                <label class="checkbox-label">
                    <input type="checkbox" id="acceptTerms">
                    Sözleşmeyi okudum ve kabul ediyorum
                </label>
                
                <button class="approve-contract-btn" id="approveBtn" disabled onclick="approveContract()">
                    Sözleşmeyi Onayla ve Ödemeye Başla
                </button>
            </div>
        </div>
    </div>

    <script>
        // Mock Database
        const users = {
            'super@admin.com': {
                id: 1,
                email: 'super@admin.com',
                password: '123456',
                fullName: 'Ahmet Yılmaz',
                role: 1,
                roleName: 'Süper Admin',
                companyId: null,
                departmentId: null,
                isContractSigned: true
            },
            'company@admin.com': {
                id: 2,
                email: 'company@admin.com',
                password: '123456',
                fullName: 'Ayşe Demir',
                role: 2,
                roleName: 'Şirket Admin',
                companyId: 1,
                companyName: 'Teknoloji A.Ş.',
                departmentId: null,
                isContractSigned: true
            },
            'manager@company.com': {
                id: 3,
                email: 'manager@company.com',
                password: '123456',
                fullName: 'Mehmet Kaya',
                role: 3,
                roleName: 'Departman Müdürü',
                companyId: 1,
                companyName: 'Teknoloji A.Ş.',
                departmentId: 1,
                departmentName: 'Yazılım',
                isContractSigned: true
            },
            'employee@company.com': {
                id: 4,
                email: 'employee@company.com',
                password: '123456',
                fullName: 'Zeynep Şahin',
                role: 4,
                roleName: 'Personel',
                companyId: 1,
                companyName: 'Teknoloji A.Ş.',
                departmentId: 1,
                departmentName: 'Yazılım',
                isContractSigned: false // Sözleşme onaylanmamış personel
            }
        };

        let currentUser = null;

        // Login functions
        function fillLogin(email) {
            document.getElementById('email').value = email;
        }

        function login() {
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            
            const user = users[email];
            
            if (user && user.password === password) {
                currentUser = user;
                
                // Hide login screen
                document.getElementById('loginScreen').style.display = 'none';
                
                // Show dashboard
                const dashboard = document.getElementById('dashboard');
                dashboard.classList.add('active');
                
                // Check contract status
                if (!user.isContractSigned) {
                    showContractModal();
                    document.getElementById('contractWarning').style.display = 'flex';
                } else {
                    document.getElementById('contractWarning').style.display = 'none';
                }
                
                // Update UI based on user role
                updateUI();
            } else {
                alert('Hatalı e-posta veya şifre!');
            }
        }

        function logout() {
            currentUser = null;
            document.getElementById('loginScreen').style.display = 'flex';
            document.getElementById('dashboard').classList.remove('active');
            document.getElementById('contractModal').classList.remove('active');
        }

        // Contract functions
        function showContractModal() {
            document.getElementById('contractModal').classList.add('active');
        }

        function closeContractModal() {
            document.getElementById('contractModal').classList.remove('active');
        }

        // Enable/disable approve button based on checkbox
        document.getElementById('acceptTerms').addEventListener('change', function(e) {
            document.getElementById('approveBtn').disabled = !e.target.checked;
        });

        function approveContract() {
            if (currentUser) {
                currentUser.isContractSigned = true;
                document.getElementById('contractWarning').style.display = 'none';
                closeContractModal();
                alert('Sözleşme başarıyla onaylandı! Ödeme işlemlerine yönlendiriliyorsunuz.');
                updateUI();
            }
        }

        // Update UI based on user role
        function updateUI() {
            if (!currentUser) return;
            
            // Update user info in sidebar
            const userInfo = document.getElementById('userInfo');
            userInfo.innerHTML = `
                <div class="user-avatar">${currentUser.fullName.charAt(0)}</div>
                <div class="user-details">
                    <h4>${currentUser.fullName}</h4>
                    <span>${getRoleBadge(currentUser.role)}</span>
                    ${currentUser.companyName ? `<p style="font-size: 11px; color: #666; margin-top: 4px;">${currentUser.companyName}</p>` : ''}
                </div>
            `;
            
            // Update sidebar menu based on role
            updateMenu();
            
            // Update main content based on role
            updateContent();
        }

        function getRoleBadge(role) {
            switch(role) {
                case 1: return 'Süper Admin';
                case 2: return 'Şirket Admin';
                case 3: return 'Departman Müdürü';
                case 4: return 'Personel';
                default: return 'Bilinmeyen Rol';
            }
        }

        function updateMenu() {
            const menu = document.getElementById('sidebarMenu');
            let menuItems = [];
            
            switch(currentUser.role) {
                case 1: // Super Admin
                    menuItems = [
                        { icon: 'fa-chart-pie', text: 'Genel Dashboard', active: true },
                        { icon: 'fa-building', text: 'Şirketler' },
                        { icon: 'fa-users', text: 'Kullanıcılar' },
                        { icon: 'fa-cog', text: 'Sistem Ayarları' },
                        { icon: 'fa-file-contract', text: 'Sözleşmeler' }
                    ];
                    document.getElementById('pageTitle').innerText = 'Süper Admin Paneli';
                    break;
                    
                case 2: // Company Admin
                    menuItems = [
                        { icon: 'fa-chart-pie', text: 'Şirket Dashboard', active: true },
                        { icon: 'fa-users', text: 'Personel Yönetimi' },
                        { icon: 'fa-building', text: 'Departmanlar' },
                        { icon: 'fa-file-invoice', text: 'İzin Talepleri' },
                        { icon: 'fa-chart-line', text: 'Raporlar' }
                    ];
                    document.getElementById('pageTitle').innerText = `${currentUser.companyName} - Şirket Paneli`;
                    break;
                    
                case 3: // Manager
                    menuItems = [
                        { icon: 'fa-chart-pie', text: 'Departman Dashboard', active: true },
                        { icon: 'fa-users', text: 'Personel Listesi' },
                        { icon: 'fa-file-invoice', text: 'Onay Bekleyenler' },
                        { icon: 'fa-clock', text: 'Puantaj' },
                        { icon: 'fa-calendar', text: 'Vardiyalar' }
                    ];
                    document.getElementById('pageTitle').innerText = `${currentUser.departmentName} Departmanı - Müdür Paneli`;
                    break;
                    
                case 4: // Employee
                    menuItems = [
                        { icon: 'fa-user', text: 'Profilim', active: true },
                        { icon: 'fa-file-invoice', text: 'İzin Taleplerim' },
                        { icon: 'fa-wallet', text: 'Masraflarım' },
                        { icon: 'fa-bell', text: 'Duyurular' },
                        { icon: 'fa-calendar', text: 'Takvim' }
                    ];
                    document.getElementById('pageTitle').innerText = 'Personel Paneli';
                    break;
            }
            
            // Build menu HTML
            menu.innerHTML = menuItems.map(item => `
                <div class="menu-item ${item.active ? 'active' : ''}" onclick="handleMenuClick(this)">
                    <i class="fas ${item.icon}"></i>
                    <span>${item.text}</span>
                </div>
            `).join('');
        }

        function handleMenuClick(element) {
            // Remove active class from all menu items
            document.querySelectorAll('.menu-item').forEach(item => {
                item.classList.remove('active');
            });
            // Add active class to clicked item
            element.classList.add('active');
            
            // Update content based on selected menu
            const menuText = element.querySelector('span').innerText;
            updateContentForMenu(menuText);
        }

        function updateContent() {
            // Default content based on role
            const contentArea = document.getElementById('contentArea');
            
            if (!currentUser.isContractSigned) {
                contentArea.innerHTML = `
                    <div class="card" style="text-align: center; padding: 50px;">
                        <i class="fas fa-file-contract" style="font-size: 60px; color: #ff4757; margin-bottom: 20px;"></i>
                        <h3 style="color: #333; margin-bottom: 10px;">Sözleşme Onayı Gerekli</h3>
                        <p style="color: #666; margin-bottom: 20px;">Sistemi kullanmaya devam etmek için kullanıcı sözleşmesini onaylamalısınız.</p>
                        <button class="login-btn" style="width: auto; padding: 12px 30px;" onclick="showContractModal()">
                            <i class="fas fa-file-signature"></i>
                            Sözleşmeyi Onayla
                        </button>
                    </div>
                `;
                return;
            }
            
            switch(currentUser.role) {
                case 1:
                    contentArea.innerHTML = getSuperAdminContent();
                    break;
                case 2:
                    contentArea.innerHTML = getCompanyAdminContent();
                    break;
                case 3:
                    contentArea.innerHTML = getManagerContent();
                    break;
                case 4:
                    contentArea.innerHTML = getEmployeeContent();
                    break;
            }
        }

        function updateContentForMenu(menuText) {
            // Burada menü tıklamalarına göre içerik güncellenebilir
            // Şimdilik sadece konsola yazdırıyoruz
            console.log('Menu clicked:', menuText);
        }

        // Role-based content generators
        function getSuperAdminContent() {
            return `
                <div class="content-cards">
                    <div class="card">
                        <div class="card-header">
                            <div class="card-icon"><i class="fas fa-building"></i></div>
                            <div class="card-title">
                                <h3>Toplam Şirket</h3>
                                <p>Aktif şirket sayısı</p>
                            </div>
                        </div>
                        <h2 style="font-size: 32px; color: #333;">24</h2>
                    </div>
                    
                    <div class="card">
                        <div class="card-header">
                            <div class="card-icon"><i class="fas fa-users"></i></div>
                            <div class="card-title">
                                <h3>Toplam Kullanıcı</h3>
                                <p>Sistemdeki aktif kullanıcılar</p>
                            </div>
                        </div>
                        <h2 style="font-size: 32px; color: #333;">1,245</h2>
                    </div>
                    
                    <div class="card">
                        <div class="card-header">
                            <div class="card-icon"><i class="fas fa-file-invoice"></i></div>
                            <div class="card-title">
                                <h3>Bekleyen Sözleşme</h3>
                                <p>Onay bekleyen sözleşmeler</p>
                            </div>
                        </div>
                        <h2 style="font-size: 32px; color: #333;">18</h2>
                    </div>
                </div>
                
                <div class="table-container">
                    <h3 style="margin-bottom: 20px;">Son Eklenen Şirketler</h3>
                    <table>
                        <thead>
                            <tr>
                                <th>Şirket Adı</th>
                                <th>Yetkili</th>
                                <th>Paket</th>
                                <th>Durum</th>
                                <th>Kayıt Tarihi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>Teknoloji A.Ş.</td>
                                <td>Ahmet Yılmaz</td>
                                <td>Professional</td>
                                <td><span class="status-badge approved">Aktif</span></td>
                                <td>15.03.2024</td>
                            </tr>
                            <tr>
                                <td>Eğitim Ltd. Şti.</td>
                                <td>Ayşe Demir</td>
                                <td>Basic</td>
                                <td><span class="status-badge approved">Aktif</span></td>
                                <td>14.03.2024</td>
                            </tr>
                            <tr>
                                <td>Sağlık A.Ş.</td>
                                <td>Mehmet Kaya</td>
                                <td>Enterprise</td>
                                <td><span class="status-badge pending">Beklemede</span></td>
                                <td>13.03.2024</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            `;
        }

        function getCompanyAdminContent() {
            return `
                <div class="content-cards">
                    <div class="card">
                        <div class="card-header">
                            <div class="card-icon"><i class="fas fa-user-tie"></i></div>
                            <div class="card-title">
                                <h3>Toplam Personel</h3>
                                <p>Aktif çalışan sayısı</p>
                            </div>
                        </div>
                        <h2 style="font-size: 32px; color: #333;">42</h2>
                    </div>
                    
                    <div class="card">
                        <div class="card-header">
                            <div class="card-icon"><i class="fas fa-building"></i></div>
                            <div class="card-title">
                                <h3>Departmanlar</h3>
                                <p>Aktif departman sayısı</p>
                            </div>
                        </div>
                        <h2 style="font-size: 32px; color: #333;">5</h2>
                    </div>
                    
                    <div class="card">
                        <div class="card-header">
                            <div class="card-icon"><i class="fas fa-clock"></i></div>
                            <div class="card-title">
                                <h3>Bekleyen İzinler</h3>
                                <p>Onay bekleyen izin talepleri</p>
                            </div>
                        </div>
                        <h2 style="font-size: 32px; color: #333;">12</h2>
                    </div>
                </div>
                
                <div class="table-container">
                    <h3 style="margin-bottom: 20px;">Personel Listesi</h3>
                    <table>
                        <thead>
                            <tr>
                                <th>Personel</th>
                                <th>Departman</th>
                                <th>Pozisyon</th>
                                <th>Durum</th>
                                <th>İşlemler</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>Zeynep Şahin</td>
                                <td>Yazılım</td>
                                <td>Frontend Developer</td>
                                <td><span class="status-badge pending">Sözleşme Bekliyor</span></td>
                                <td>
                                    <button class="action-btn approve"><i class="fas fa-check"></i></button>
                                    <button class="action-btn reject"><i class="fas fa-times"></i></button>
                                </td>
                            </tr>
                            <tr>
                                <td>Ali Öztürk</td>
                                <td>Pazarlama</td>
                                <td>Uzman</td>
                                <td><span class="status-badge approved">Aktif</span></td>
                                <td>
                                    <button class="action-btn approve"><i class="fas fa-check"></i></button>
                                    <button class="action-btn reject"><i class="fas fa-times"></i></button>
                                </td>
                            </tr>
                            <tr>
                                <td>Can Yılmaz</td>
                                <td>İK</td>
                                <td>Uzman Yardımcısı</td>
                                <td><span class="status-badge approved">Aktif</span></td>
                                <td>
                                    <button class="action-btn approve"><i class="fas fa-check"></i></button>
                                    <button class="action-btn reject"><i class="fas fa-times"></i></button>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            `;
        }

        function getManagerContent() {
            return `
                <div class="content-cards">
                    <div class="card">
                        <div class="card-header">
                            <div class="card-icon"><i class="fas fa-users"></i></div>
                            <div class="card-title">
                                <h3>Ekip Üyeleri</h3>
                                <p>Departmandaki personel</p>
                            </div>
                        </div>
                        <h2 style="font-size: 32px; color: #333;">8</h2>
                    </div>
                    
                    <div class="card">
                        <div class="card-header">
                            <div class="card-icon"><i class="fas fa-clock"></i></div>
                            <div class="card-title">
                                <h3>Bekleyen İzin</h3>
                                <p>Onaylanmayı bekleyen</p>
                            </div>
                        </div>
                        <h2 style="font-size: 32px; color: #333;">3</h2>
                    </div>
                    
                    <div class="card">
                        <div class="card-header">
                            <div class="card-icon"><i class="fas fa-wallet"></i></div>
                            <div class="card-title">
                                <h3>Bekleyen Masraf</h3>
                                <p>Onay bekleyen masraflar</p>
                            </div>
                        </div>
                        <h2 style="font-size: 32px; color: #333;">5</h2>
                    </div>
                </div>
                
                <div class="table-container">
                    <h3 style="margin-bottom: 20px;">Onay Bekleyen Talepler</h3>
                    <table>
                        <thead>
                            <tr>
                                <th>Personel</th>
                                <th>Talep Türü</th>
                                <th>Tarih</th>
                                <th>Süre/Tutar</th>
                                <th>Durum</th>
                                <th>İşlemler</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>Zeynep Şahin</td>
                                <td>Yıllık İzin</td>
                                <td>20-25 Mart</td>
                                <td>5 gün</td>
                                <td><span class="status-badge pending">Bekliyor</span></td>
                                <td>
                                    <button class="action-btn approve" onclick="alert('Talep onaylandı!')"><i class="fas fa-check"></i> Onayla</button>
                                    <button class="action-btn reject" onclick="alert('Talep reddedildi!')"><i class="fas fa-times"></i> Reddet</button>
                                </td>
                            </tr>
                            <tr>
                                <td>Ali Öztürk</td>
                                <td>Masraf</td>
                                <td>15 Mart</td>
                                <td>250 TL</td>
                                <td><span class="status-badge pending">Bekliyor</span></td>
                                <td>
                                    <button class="action-btn approve" onclick="alert('Talep onaylandı!')"><i class="fas fa-check"></i> Onayla</button>
                                    <button class="action-btn reject" onclick="alert('Talep reddedildi!')"><i class="fas fa-times"></i> Reddet</button>
                                </td>
                            </tr>
                            <tr>
                                <td>Can Yılmaz</td>
                                <td>Hastalık İzni</td>
                                <td>18 Mart</td>
                                <td>1 gün</td>
                                <td><span class="status-badge pending">Bekliyor</span></td>
                                <td>
                                    <button class="action-btn approve" onclick="alert('Talep onaylandı!')"><i class="fas fa-check"></i> Onayla</button>
                                    <button class="action-btn reject" onclick="alert('Talep reddedildi!')"><i class="fas fa-times"></i> Reddet</button>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            `;
        }

        function getEmployeeContent() {
            return `
                <div class="content-cards">
                    <div class="card">
                        <div class="card-header">
                            <div class="card-icon"><i class="fas fa-calendar-alt"></i></div>
                            <div class="card-title">
                                <h3>Kalan İzin</h3>
                                <p>Yıllık izin hakkınız</p>
                            </div>
                        </div>
                        <h2 style="font-size: 32px; color: #333;">14 gün</h2>
                    </div>
                    
                    <div class="card">
                        <div class="card-header">
                            <div class="card-icon"><i class="fas fa-clock"></i></div>
                            <div class="card-title">
                                <h3>Bekleyen İzin</h3>
                                <p>Onay bekleyen talepler</p>
                            </div>
                        </div>
                        <h2 style="font-size: 32px; color: #333;">1</h2>
                    </div>
                    
                    <div class="card">
                        <div class="card-header">
                            <div class="card-icon"><i class="fas fa-wallet"></i></div>
                            <div class="card-title">
                                <h3>Son Masraf</h3>
                                <p>Son masraf tutarınız</p>
                            </div>
                        </div>
                        <h2 style="font-size: 32px; color: #333;">250 TL</h2>
                    </div>
                </div>
                
                <div class="table-container">
                    <h3 style="margin-bottom: 20px;">İzin Taleplerim</h3>
                    <table>
                        <thead>
                            <tr>
                                <th>Talep Türü</th>
                                <th>Başlangıç</th>
                                <th>Bitiş</th>
                                <th>Süre</th>
                                <th>Durum</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>Yıllık İzin</td>
                                <td>20 Mart 2024</td>
                                <td>25 Mart 2024</td>
                                <td>5 gün</td>
                                <td><span class="status-badge pending">Onay Bekliyor</span></td>
                            </tr>
                            <tr>
                                <td>Hastalık İzni</td>
                                <td>10 Mart 2024</td>
                                <td>11 Mart 2024</td>
                                <td>2 gün</td>
                                <td><span class="status-badge approved">Onaylandı</span></td>
                            </tr>
                            <tr>
                                <td>Yıllık İzin</td>
                                <td>1 Şubat 2024</td>
                                <td>5 Şubat 2024</td>
                                <td>5 gün</td>
                                <td><span class="status-badge approved">Onaylandı</span></td>
                            </tr>
                        </tbody>
                    </table>
                    
                    <div style="margin-top: 25px; text-align: right;">
                        <button class="login-btn" style="width: auto; padding: 12px 25px;" onclick="alert('Yeni izin talebi oluşturma sayfasına yönlendiriliyorsunuz.')">
                            <i class="fas fa-plus"></i>
                            Yeni İzin Talebi
                        </button>
                    </div>
                </div>
            `;
        }

        // Toggle sidebar on mobile (opsiyonel)
        function toggleSidebar() {
            document.getElementById('sidebar').classList.toggle('active');
        }

        // Initialize
        document.getElementById('loginScreen').style.display = 'flex';
    </script>
</body>
</html>
- Tüm hassas veriler 256-bit şifreleme ile korunur
- Veritabanında güvenli bir şekilde saklanır

### Oturum ID
- Her onay işlemi için benzersiz oturum ID oluşturulur
- İzlenebilirlik ve denetim için kullanılır

## Kullanım Akışı

### 1. Bordro Görüntüleme
1. Kullanıcı bordro listesinden ilgili bordroyu seçer
2. Bordro detay modalı açılır
3. Onay durumu kontrol edilir

### 2. Onay Başlatma
1. Eğer bordro onay bekliyor durumundaysa, "Güvenli Onay Penceresini Aç" butonu gösterilir
2. Kullanıcı butona tıkladığında yeni bir pencere açılır
3. Pencere tam ekran olarak açılır (1200x900 piksel)

### 3. Doğrulama Yöntemi Seçimi
1. Kullanıcı 3 yöntemden birini seçer:
   - Dijital İmza
   - Kimlik Belgesi
   - Şifre Doğrulama

### 4. Doğrulama
- **Dijital İmza:** Canvas üzerinde imza çizilir
- **Kimlik Belgesi:** Dosya yüklenir ve önizleme gösterilir
- **Şifre:** Şifre alanına girilir ve doğrulanır

### 5. Onay Tamamlama
1. Doğrulama tamamlandığında "Onayla ve Kaydet" butonu aktif olur
2. Kullanıcı butona tıklar
3. Onay bilgileri veritabanına kaydedilir
4. Bordro durumu "onaylandı" olarak güncellenir
5. Başarı mesajı gösterilir
6. Pencere 3 saniye sonra otomatik kapanır

## Onay Geçmişi

### Görüntüleme
- Bordro detay sayfasında onay geçmişi görüntülenebilir
- Her onay için şu bilgiler gösterilir:
  - Onaylayan kişi adı
  - Onay tarihi ve saati
  - Doğrulama yöntemi
  - IP adresi
  - Dijital imza (varsa)
  - Kimlik belgesi (varsa)

### Dışa Aktarma
- Onay kayıtları JSON formatında dışa aktarılabilir
- Yedekleme ve arşivleme için kullanılabilir

## Teknik Detaylar

### Veritabanı Tablosu
```sql
bordro_approvals
- id (uuid, primary key)
- bordro_id (uuid, foreign key)
- company_id (uuid, foreign key)
- employee_id (uuid, foreign key)
- employee_name (text)
- verification_method (text)
- signature_data (text, nullable)
- id_document_data (text, nullable)
- passcode_hash (text, nullable)
- approval_status (text)
- ip_address (text, nullable)
- user_agent (text, nullable)
- timestamp (timestamptz)
```

### RLS (Row Level Security)
- Her kullanıcı sadece kendi şirketinin onay kayıtlarını görebilir
- Onay kayıtları oluşturulduktan sonra değiştirilemez
- Silme işlemi sadece admin kullanıcılar tarafından yapılabilir

### API Endpoints
- `bordroService.createApproval()` - Yeni onay oluşturma
- `bordroService.getApprovals()` - Onay geçmişini getirme
- `bordroService.verifyEmployeePasscode()` - Şifre doğrulama
- `bordroService.hasEmployeePasscode()` - Şifre varlığı kontrolü

## Yasal Uyumluluk

### KVKK Uyumu
- Kişisel veriler şifrelenerek saklanır
- Kullanıcı onayı ile işlenir
- Saklama süreleri tanımlanmıştır

### İş Kanunu Uyumu
- Bordro onayları yasal geçerliliğe sahiptir
- Zaman damgası ile ispat niteliği taşır
- Denetim için kayıt altına alınır

## Bakım ve Destek

### Sorun Giderme
1. **Onay penceresi açılmıyor:**
   - Pop-up engelleyici kontrol edilmeli
   - Tarayıcı ayarları kontrol edilmeli

2. **İmza çizilemiyor:**
   - Canvas desteği kontrol edilmeli
   - Tarayıcı güncellenmelidir

3. **Kimlik belgesi yüklenemiyor:**
   - Dosya boyutu kontrolü
   - Dosya formatı kontrolü

4. **Şifre doğrulama başarısız:**
   - Şifre tanımlı mı kontrol edilmeli
   - Caps Lock kontrolü

### Güncelleme Notları
- v1.0.0 - İlk sürüm, 3 doğrulama yöntemi
- v1.1.0 - Onay geçmişi eklendi
- v1.2.0 - Gelişmiş güvenlik özellikleri

## Öneriler

1. **Güvenlik:**
   - Şifreleri düzenli olarak değiştirin
   - IP adresi takibini aktif tutun
   - HTTPS kullanımını zorunlu kılın

2. **Kullanım:**
   - Çalışanlara eğitim verin
   - Test ortamında deneyin
   - Yedekleme yapın

3. **Performans:**
   - Eski onay kayıtlarını arşivleyin
   - Görsel boyutlarını optimize edin
   - Veritabanı indekslemesi yapın
