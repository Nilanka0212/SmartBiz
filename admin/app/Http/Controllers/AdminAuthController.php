<?php

namespace App\Http\Controllers;

use App\Models\Admin;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Session;

class AdminAuthController extends Controller {

    public function showLogin() {
        if (Session::get('admin')) {
            return redirect('/admin/dashboard');
        }
        return view('admin.login');
    }

    public function login(Request $request) {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required',
        ]);

        $admin = Admin::where('email',
                        $request->email)->first();

        if ($admin && Hash::check(
                $request->password, $admin->password)) {
            Session::put('admin', $admin);
            return redirect('/admin/dashboard');
        }

        return back()->withErrors([
            'email' => 'Invalid email or password'
        ]);
    }

    public function logout() {
        Session::forget('admin');
        return redirect('/admin/login');
    }
}