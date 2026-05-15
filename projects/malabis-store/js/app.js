// ===== PRODUCTS DATABASE =====
const products = [
    // FORMAL
    {
        id: 1,
        name: "Thobe Blanco Premium",
        category: "formal",
        price: 12000,
        description: "Thobe tradicional de algodón puro",
        emoji: "👳"
    },
    {
        id: 2,
        name: "Kandura Elegante",
        category: "formal",
        price: 10000,
        description: "Kandura de seda con bordados",
        emoji: "🧥"
    },
    {
        id: 3,
        name: "Ghutra Tradicional",
        category: "formal",
        price: 3500,
        description: "Ghutra blanca y roja",
        emoji: "🎀"
    },
    {
        id: 4,
        name: "Iqal Dorado",
        category: "formal",
        price: 2500,
        description: "Iqal de seda dorada",
        emoji: "👑"
    },

    // INFORMAL
    {
        id: 5,
        name: "Dishdasha Casual",
        category: "informal",
        price: 6000,
        description: "Dishdasha cómoda de algodón",
        emoji: "👕"
    },
    {
        id: 6,
        name: "Abaya Moderna",
        category: "informal",
        price: 8000,
        description: "Abaya con diseño contemporáneo",
        emoji: "👗"
    },
    {
        id: 7,
        name: "Hijab Estampado",
        category: "informal",
        price: 1500,
        description: "Hijab de algodón con patrones",
        emoji: "🧣"
    },
    {
        id: 8,
        name: "Niqab Elegante",
        category: "informal",
        price: 3000,
        description: "Niqab de tela suave",
        emoji: "🎭"
    },

    // DEPORTIVA
    {
        id: 9,
        name: "Thobe Deportivo",
        category: "deportiva",
        price: 5000,
        description: "Thobe ligero para actividades",
        emoji: "🏃"
    },
    {
        id: 10,
        name: "Zapatillas Árabes",
        category: "deportiva",
        price: 4500,
        description: "Zapatillas deportivas modernas",
        emoji: "👟"
    },
    {
        id: 11,
        name: "Pantalón Harem",
        category: "deportiva",
        price: 3500,
        description: "Pantalón harem cómodo",
        emoji: "👖"
    },
    {
        id: 12,
        name: "Sudadera Árabe",
        category: "deportiva",
        price: 4000,
        description: "Sudadera con motivos árabes",
        emoji: "🧥"
    },

    // DE FIESTA
    {
        id: 13,
        name: "Abaya de Gala",
        category: "fiesta",
        price: 15000,
        description: "Abaya bordada con pedrería",
        emoji: "✨"
    },
    {
        id: 14,
        name: "Thobe de Fiesta",
        category: "fiesta",
        price: 14000,
        description: "Thobe con bordados dorados",
        emoji: "👑"
    },
    {
        id: 15,
        name: "Hijab de Fiesta",
        category: "fiesta",
        price: 3500,
        description: "Hijab con detalles brillantes",
        emoji: "💎"
    },
    {
        id: 16,
        name: "Cinturón Joyero",
        category: "fiesta",
        price: 5000,
        description: "Cinturón árabe con joyas",
        emoji: "⚜️"
    },

    // ACCESORIOS
    {
        id: 17,
        name: "Pulseras Árabes",
        category: "accesorios",
        price: 2500,
        description: "Set de pulseras doradas",
        emoji: "💍"
    },
    {
        id: 18,
        name: "Collar Tradicional",
        category: "accesorios",
        price: 3000,
        description: "Collar árabe de oro",
        emoji: "⌚"
    },
    {
        id: 19,
        name: "Kohl y Maquillaje",
        category: "accesorios",
        price: 1200,
        description: "Kit de maquillaje árabe",
        emoji: "💄"
    },
    {
        id: 20,
        name: "Bolso Árabe",
        category: "accesorios",
        price: 4500,
        description: "Bolso bordado tradicional",
        emoji: "👜"
    },

    // POR ENCARGO
    {
        id: 21,
        name: "Thobe Personalizado",
        category: "encargo",
        price: 0,
        description: "Thobe a tu medida y diseño",
        emoji: "🎨"
    },
    {
        id: 22,
        name: "Abaya Diseño Exclusivo",
        category: "encargo",
        price: 0,
        description: "Abaya con tu diseño especial",
        emoji: "✨"
    },
    {
        id: 23,
        name: "Bordado Personalizado",
        category: "encargo",
        price: 0,
        description: "Bordado árabe con tu nombre",
        emoji: "🧵"
    },
    {
        id: 24,
        name: "Confección Árabe a Medida",
        category: "encargo",
        price: 0,
        description: "Ropa árabe confeccionada a medida",
        emoji: "📏"
    }
];

// ===== STATE =====
let cart = [];
let currentCategory = "todos";

// ===== DOM ELEMENTS =====
const productsGrid = document.getElementById("productsGrid");
const cartItemsContainer = document.getElementById("cartItems");
const totalPriceSpan = document.getElementById("totalPrice");
const clearCartBtn = document.getElementById("clearCartBtn");
const submitOrderBtn = document.getElementById("submitOrderBtn");
const navButtons = document.querySelectorAll(".nav-btn");
const notificationModal = document.getElementById("notificationModal");
const closeBtn = document.querySelector(".close");

// ===== INITIALIZATION =====
document.addEventListener("DOMContentLoaded", () => {
    renderProducts();
    setupEventListeners();
    loadCartFromStorage();
});

// ===== EVENT LISTENERS =====
function setupEventListeners() {
    // Category filters
    navButtons.forEach(btn => {
        btn.addEventListener("click", (e) => {
            navButtons.forEach(b => b.classList.remove("active"));
            e.target.classList.add("active");
            currentCategory = e.target.dataset.category;
            renderProducts();
        });
    });

    // Cart actions
    clearCartBtn.addEventListener("click", clearCart);
    submitOrderBtn.addEventListener("click", submitOrder);

    // Modal close
    closeBtn.addEventListener("click", closeModal);
    window.addEventListener("click", (e) => {
        if (e.target === notificationModal) {
            closeModal();
        }
    });
}

// ===== RENDER PRODUCTS =====
function renderProducts() {
    const filteredProducts = currentCategory === "todos" 
        ? products 
        : products.filter(p => p.category === currentCategory);

    productsGrid.innerHTML = filteredProducts.map(product => `
        <div class="product-card">
            <div class="product-image">${product.emoji}</div>
            <div class="product-info">
                <span class="product-category">${getCategoryLabel(product.category)}</span>
                <h3 class="product-name">${product.name}</h3>
                <p class="product-description">${product.description}</p>
                <div class="product-price">$${product.price.toLocaleString()}</div>
                <div class="product-actions">
                    <div class="product-quantity">
                        <button class="qty-btn" onclick="decreaseQty(${product.id})">−</button>
                        <input type="number" class="qty-input" id="qty-${product.id}" value="1" min="1">
                        <button class="qty-btn" onclick="increaseQty(${product.id})">+</button>
                    </div>
                    <button class="add-to-cart-btn" onclick="addToCart(${product.id})">Agregar</button>
                </div>
            </div>
        </div>
    `).join("");
}

// ===== CART FUNCTIONS =====
function addToCart(productId) {
    const product = products.find(p => p.id === productId);
    const qtyInput = document.getElementById(`qty-${productId}`);
    const quantity = parseInt(qtyInput.value) || 1;

    const existingItem = cart.find(item => item.id === productId);

    if (existingItem) {
        existingItem.quantity += quantity;
    } else {
        cart.push({
            ...product,
            quantity: quantity
        });
    }

    qtyInput.value = 1;
    updateCart();
    saveCartToStorage();
    showAddedNotification(product.name);
}

function removeFromCart(productId) {
    cart = cart.filter(item => item.id !== productId);
    updateCart();
    saveCartToStorage();
}

function updateCart() {
    renderCartItems();
    updateTotalPrice();
}

function renderCartItems() {
    if (cart.length === 0) {
        cartItemsContainer.innerHTML = '<p class="empty-cart">Selecciona productos para comenzar</p>';
        submitOrderBtn.disabled = true;
        return;
    }

    submitOrderBtn.disabled = false;
    cartItemsContainer.innerHTML = cart.map(item => `
        <div class="cart-item">
            <div>
                <div class="cart-item-name">${item.name}</div>
                <div class="cart-item-qty">Cantidad: ${item.quantity}</div>
            </div>
            <div style="display: flex; align-items: center; gap: 10px;">
                <div class="cart-item-price">$${(item.price * item.quantity).toLocaleString()}</div>
                <button class="cart-item-remove" onclick="removeFromCart(${item.id})">✕</button>
            </div>
        </div>
    `).join("");
}

function updateTotalPrice() {
    const total = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    totalPriceSpan.textContent = total.toLocaleString();
}

function clearCart() {
    if (cart.length === 0) return;
    if (confirm("¿Estás seguro de que deseas limpiar el carrito?")) {
        cart = [];
        updateCart();
        saveCartToStorage();
    }
}

// ===== QUANTITY CONTROLS =====
function increaseQty(productId) {
    const input = document.getElementById(`qty-${productId}`);
    input.value = parseInt(input.value) + 1;
}

function decreaseQty(productId) {
    const input = document.getElementById(`qty-${productId}`);
    if (parseInt(input.value) > 1) {
        input.value = parseInt(input.value) - 1;
    }
}

// ===== ORDER SUBMISSION =====
function submitOrder() {
    if (cart.length === 0) {
        alert("Tu carrito está vacío");
        return;
    }

    const orderData = {
        id: generateOrderId(),
        timestamp: new Date().toLocaleString("es-AR"),
        items: cart,
        total: cart.reduce((sum, item) => sum + (item.price * item.quantity), 0),
        customerInfo: {
            location: "Rawson, San Juan",
            storeLocation: "Calle Mendoza entre Calvento y Progreso"
        }
    };

    // Simulate sending to owner
    console.log("Pedido enviado al dueño:", orderData);
    
    // Show customer notification
    showOrderConfirmation(orderData);

    // Simulate owner notification (in real app, this would be via email/WhatsApp)
    simulateOwnerNotification(orderData);

    // Clear cart
    cart = [];
    updateCart();
    saveCartToStorage();
}

function generateOrderId() {
    return "MAL-" + Date.now().toString().slice(-8);
}

function simulateOwnerNotification(orderData) {
    console.log("📧 NOTIFICACIÓN AL DUEÑO:");
    console.log("Nuevo pedido recibido:", orderData.id);
    console.log("Total: $" + orderData.total.toLocaleString());
    console.log("Detalles:", orderData.items.map(i => `${i.name} (x${i.quantity})`).join(", "));
}

// ===== NOTIFICATIONS =====
function showOrderConfirmation(orderData) {
    const itemsList = orderData.items
        .map(item => `<p>• ${item.name} (x${item.quantity}) - $${(item.price * item.quantity).toLocaleString()}</p>`)
        .join("");

    const notificationHTML = `
        <div class="notification-icon">✅</div>
        <div class="notification-title">¡Reserva Confirmada!</div>
        <div class="notification-message">
            Tu pedido ha sido registrado exitosamente. El dueño de Malabis se pondrá en contacto pronto.
        </div>
        <div class="notification-details">
            <p><strong>ID de Pedido:</strong> ${orderData.id}</p>
            <p><strong>Fecha:</strong> ${orderData.timestamp}</p>
            <p><strong>Total:</strong> $${orderData.total.toLocaleString()}</p>
            <p><strong>Próximo paso:</strong> Realizar depósito de reserva</p>
        </div>
        <div style="background: #FFF3CD; padding: 15px; border-radius: 8px; margin-bottom: 20px; text-align: left;">
            <p><strong>📍 Ubicación de la tienda:</strong></p>
            <p>Calle Mendoza entre Calvento y Progreso</p>
            <p>A pasitos del Café América</p>
            <p>Rawson - San Juan - Argentina</p>
        </div>
        <button class="notification-btn" onclick="closeModal()">Entendido</button>
    `;

    document.getElementById("notificationContent").innerHTML = notificationHTML;
    notificationModal.style.display = "block";
}

function showAddedNotification(productName) {
    // Quick visual feedback (could be a toast notification)
    const btn = event.target;
    const originalText = btn.textContent;
    btn.textContent = "✓ Agregado";
    btn.style.background = "linear-gradient(135deg, #2ECC71, #27AE60)";
    
    setTimeout(() => {
        btn.textContent = originalText;
        btn.style.background = "";
    }, 1500);
}

function closeModal() {
    notificationModal.style.display = "none";
}

// ===== UTILITY FUNCTIONS =====
function getCategoryLabel(category) {
    const labels = {
        formal: "Formal",
        informal: "Casual",
        deportiva: "Deportiva",
        fiesta: "Fiesta",
        accesorios: "Accesorios",
        encargo: "Encargo"
    };
    return labels[category] || category;
}

// ===== LOCAL STORAGE =====
function saveCartToStorage() {
    localStorage.setItem("malabisCart", JSON.stringify(cart));
}

function loadCartFromStorage() {
    const saved = localStorage.getItem("malabisCart");
    if (saved) {
        cart = JSON.parse(saved);
        updateCart();
    }
}

// ===== PERFORMANCE OPTIMIZATION =====
// Lazy load images and optimize rendering
if ("IntersectionObserver" in window) {
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = "1";
            }
        });
    });

    document.addEventListener("DOMContentLoaded", () => {
        document.querySelectorAll(".product-card").forEach(card => {
            observer.observe(card);
        });
    });
}