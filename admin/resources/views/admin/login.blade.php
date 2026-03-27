<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SmartBiz Admin Login</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body {
            background: linear-gradient(135deg, #ff8c00, #e65c00);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .login-card {
            background: white;
            border-radius: 20px;
            padding: 40px;
            width: 100%;
            max-width: 420px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.2);
        }
        .btn-orange {
            background: #ff8c00;
            color: white;
            border: none;
        }
        .btn-orange:hover {
            background: #e65c00;
            color: white;
        }
        .form-control:focus {
            border-color: #ff8c00;
            box-shadow: 0 0 0 0.2rem rgba(255,140,0,0.25);
        }
    </style>
</head>
<body>
<div class="login-card">
    <div class="text-center mb-4">
        <div style="width:70px;height:70px;background:#ff8c00;
                    border-radius:15px;display:inline-flex;
                    align-items:center;justify-content:center;
                    margin-bottom:15px">
            <i class="fas fa-store fa-2x text-white"></i>
        </div>
        <h4 class="fw-bold">ShopFlow Admin</h4>
        <p class="text-muted">Sign in to your account</p>
    </div>

    @if($errors->any())
        <div class="alert alert-danger">
            {{ $errors->first() }}
        </div>
    @endif

    <form method="POST" action="/admin/login">
        @csrf
        <div class="mb-3">
            <label class="form-label fw-semibold">
                Email Address
            </label>
            <input type="email" name="email"
                   class="form-control form-control-lg"
                   placeholder="admin@shopflow.com"
                   value="{{ old('email') }}" required>
        </div>
        <div class="mb-4">
            <label class="form-label fw-semibold">
                Password
            </label>
            <input type="password" name="password"
                   class="form-control form-control-lg"
                   placeholder="••••••••" required>
        </div>
        <button type="submit"
                class="btn btn-orange btn-lg w-100 fw-bold">
            Sign In
        </button>
    </form>
</div>
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
</body>
</html>