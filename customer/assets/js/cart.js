// ── Cart Manager ──
const Cart = {
    shop: null,
    items: {},

    normalizeShop(shop) {
        if (!shop || !shop.id) return null;
        return {
            id: String(shop.id),
            name: shop.name || 'This shop'
        };
    },

    canUseShop(shop) {
        const nextShop = this.normalizeShop(shop);
        if (!nextShop) return true;

        const hasItems = Object.keys(this.items).length > 0;
        if (!this.shop || !hasItems) {
            this.shop = nextShop;
            return true;
        }

        return String(this.shop.id) === String(nextShop.id);
    },

    add(id, name, price, shop) {
        const nextShop = this.normalizeShop(shop);
        if (!this.canUseShop(nextShop)) {
            showToast(
                `You can only order from ${this.shop.name}. Finish or clear that cart first.`
            );
            return false;
        }

        if (this.items[id]) {
            this.items[id].qty++;
        } else {
            this.items[id] = { id, name, price, qty: 1 };
        }
        if (nextShop) {
            this.shop = nextShop;
        }
        this.save();
        this.updateUI(id);
        this.updateCartBadge();
        showToast(`${name} added to cart`);
        return true;
    },

    remove(id) {
        if (this.items[id]) {
            this.items[id].qty--;
            if (this.items[id].qty <= 0) {
                delete this.items[id];
            }
        }
        this.save();
        this.updateUI(id);
        this.updateCartBadge();
    },

    getQty(id) {
        return this.items[id] ? this.items[id].qty : 0;
    },

    getTotal() {
        return Object.values(this.items).reduce(
            (sum, item) => sum + (item.price * item.qty), 0
        );
    },

    getCount() {
        return Object.values(this.items).reduce(
            (sum, item) => sum + item.qty, 0
        );
    },

    save() {
        localStorage.setItem('cart', JSON.stringify({
            shop: this.shop,
            items: this.items
        }));
    },

    load() {
        const saved = localStorage.getItem('cart');
        if (!saved) return;

        try {
            const parsed = JSON.parse(saved);
            if (parsed && typeof parsed === 'object' && parsed.items) {
                this.shop = this.normalizeShop(parsed.shop);
                this.items = parsed.items;
                return;
            }

            this.shop = null;
            this.items = parsed || {};
        } catch (e) {
            this.shop = null;
            this.items = {};
        }
    },

    clear() {
        this.shop = null;
        this.items = {};
        this.save();
    },

    clearIfMatchesShop(shopId) {
        if (!shopId || !this.shop) return;
        if (String(this.shop.id) === String(shopId)) {
            this.clear();
        }
    },

    updateUI(id) {
        const qty     = this.getQty(id);
        const addBtn  = document.getElementById(`add-${id}`);
        const qtyCtrl = document.getElementById(`qty-${id}`);
        const qtyNum  = document.getElementById(`qtynum-${id}`);

        if (qty === 0) {
            if (addBtn)  addBtn.style.display  = 'flex';
            if (qtyCtrl) qtyCtrl.style.display = 'none';
        } else {
            if (addBtn)  addBtn.style.display  = 'none';
            if (qtyCtrl) qtyCtrl.style.display = 'flex';
            if (qtyNum)  qtyNum.textContent    = qty;
        }
    },

    updateCartBadge() {
        const badge = document.getElementById('cart-badge');
        const count = this.getCount();
        if (badge) {
            badge.textContent    = count;
            badge.style.display  = count > 0 ? 'flex' : 'none';
        }
    },

    renderCartModal() {
        const container = document.getElementById('cart-items');
        const totalEl   = document.getElementById('cart-total');
        const checkoutBtn = document.getElementById('checkout-btn');

        if (!container) return;

        const items = Object.values(this.items);

        if (items.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <div class="icon">🛒</div>
                    <p>Your cart is empty</p>
                </div>`;
            if (checkoutBtn) checkoutBtn.disabled = true;
            return;
        }

        if (checkoutBtn) checkoutBtn.disabled = false;

        container.innerHTML = items.map(item => `
            <div class="cart-item">
                <div>
                    <div class="cart-item-name">${item.name}</div>
                    <div style="font-size:12px;color:#888">
                        Rs. ${item.price} × ${item.qty}
                    </div>
                </div>
                <div class="cart-item-price">
                    Rs. ${(item.price * item.qty).toFixed(2)}
                </div>
            </div>
        `).join('');

        if (totalEl) {
            totalEl.textContent =
                'Rs. ' + this.getTotal().toFixed(2);
        }
    }
};

const OrderHistory = {
    storageKey: 'order_history',

    load() {
        const saved = localStorage.getItem(this.storageKey);
        if (!saved) return [];

        try {
            const parsed = JSON.parse(saved);
            return Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            return [];
        }
    },

    save(order) {
        if (!order || !order.id) return;

        const entry = {
            id: String(order.id),
            owner_id: order.owner_id ? String(order.owner_id) : '',
            shop_name: order.shop_name || '',
            saved_at: order.saved_at || new Date().toISOString()
        };

        const items = this.load().filter(existing =>
            String(existing.id) !== entry.id
        );

        items.unshift(entry);
        localStorage.setItem(
            this.storageKey,
            JSON.stringify(items.slice(0, 50))
        );
    },

    getByShop(shopId) {
        if (!shopId) return this.load();

        return this.load().filter(order =>
            String(order.owner_id) === String(shopId)
        );
    },

    remove(orderId) {
        const items = this.load().filter(order =>
            String(order.id) !== String(orderId)
        );
        localStorage.setItem(this.storageKey, JSON.stringify(items));
    }
};

// ── Toast notification ──
function showToast(msg) {
    const toast = document.getElementById('toast');
    if (!toast) return;
    toast.textContent = msg;
    toast.classList.add('show');
    setTimeout(() => toast.classList.remove('show'), 2000);
}

// ── Modal controls ──
function openCart() {
    Cart.renderCartModal();
    document.getElementById('cart-modal').classList.add('show');
}

function closeCart() {
    document.getElementById('cart-modal').classList.remove('show');
}

// ── Initialize ──
document.addEventListener('DOMContentLoaded', () => {
    Cart.load();
    Cart.updateCartBadge();

    // Update all product UIs
    document.querySelectorAll('[data-product-id]').forEach(el => {
        Cart.updateUI(el.dataset.productId);
    });
});
