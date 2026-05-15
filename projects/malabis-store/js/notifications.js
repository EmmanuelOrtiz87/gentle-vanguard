// ===== NOTIFICATIONS SYSTEM =====
// This file handles all notification-related functionality

class NotificationSystem {
    constructor() {
        this.notifications = [];
        this.maxNotifications = 5;
    }

    // Add a notification to the queue
    add(notification) {
        this.notifications.push(notification);
        if (this.notifications.length > this.maxNotifications) {
            this.notifications.shift();
        }
        this.render();
    }

    // Create a success notification
    success(title, message) {
        this.add({
            type: 'success',
            title: title,
            message: message,
            icon: '✅',
            timestamp: new Date()
        });
    }

    // Create an info notification
    info(title, message) {
        this.add({
            type: 'info',
            title: title,
            message: message,
            icon: 'ℹ️',
            timestamp: new Date()
        });
    }

    // Create a warning notification
    warning(title, message) {
        this.add({
            type: 'warning',
            title: title,
            message: message,
            icon: '⚠️',
            timestamp: new Date()
        });
    }

    // Create an error notification
    error(title, message) {
        this.add({
            type: 'error',
            title: title,
            message: message,
            icon: '❌',
            timestamp: new Date()
        });
    }

    // Render notifications (for future implementation)
    render() {
        // This can be extended to show toast notifications
        // For now, notifications are shown via modal
    }

    // Clear all notifications
    clear() {
        this.notifications = [];
    }

    // Get notification history
    getHistory() {
        return this.notifications;
    }
}

// Initialize notification system
const notificationSystem = new NotificationSystem();

// ===== OWNER NOTIFICATION SIMULATOR =====
class OwnerNotificationSimulator {
    constructor() {
        this.orders = [];
        this.isEnabled = true;
    }

    // Simulate sending notification to owner
    sendOrderNotification(orderData) {
        if (!this.isEnabled) return;

        const notification = {
            type: 'new_order',
            orderId: orderData.id,
            timestamp: orderData.timestamp,
            items: orderData.items,
            total: orderData.total,
            customerLocation: orderData.customerInfo.location,
            status: 'pending_confirmation'
        };

        this.orders.push(notification);
        this.logNotification(notification);
        this.simulateSound();
    }

    // Log notification to console (simulating backend)
    logNotification(notification) {
        console.group('📬 NOTIFICACIÓN AL DUEÑO - MALABIS');
        console.log('Tipo:', notification.type);
        console.log('ID Pedido:', notification.orderId);
        console.log('Fecha/Hora:', notification.timestamp);
        console.log('Cantidad de artículos:', notification.items.length);
        console.log('Total:', `$${notification.total.toLocaleString()}`);
        console.log('Artículos:');
        notification.items.forEach(item => {
            console.log(`  • ${item.name} (x${item.quantity}) - $${(item.price * item.quantity).toLocaleString()}`);
        });
        console.log('Estado:', notification.status);
        console.log('---');
        console.log('⏰ El dueño debe confirmar la reserva y contactar al cliente');
        console.groupEnd();
    }

    // Simulate notification sound
    simulateSound() {
        // In a real app, this would play an actual sound
        console.log('🔔 Sonido de notificación (simulado)');
    }

    // Get all orders
    getOrders() {
        return this.orders;
    }

    // Get pending orders
    getPendingOrders() {
        return this.orders.filter(o => o.status === 'pending_confirmation');
    }

    // Confirm an order (owner action)
    confirmOrder(orderId) {
        const order = this.orders.find(o => o.orderId === orderId);
        if (order) {
            order.status = 'confirmed';
            console.log(`✅ Pedido ${orderId} confirmado por el dueño`);
        }
    }

    // Reject an order (owner action)
    rejectOrder(orderId, reason) {
        const order = this.orders.find(o => o.orderId === orderId);
        if (order) {
            order.status = 'rejected';
            order.rejectionReason = reason;
            console.log(`❌ Pedido ${orderId} rechazado: ${reason}`);
        }
    }

    // Toggle notifications on/off
    toggle() {
        this.isEnabled = !this.isEnabled;
        console.log(`Notificaciones al dueño: ${this.isEnabled ? 'ACTIVADAS' : 'DESACTIVADAS'}`);
    }
}

// Initialize owner notification simulator
const ownerNotifications = new OwnerNotificationSimulator();

// ===== CUSTOMER NOTIFICATION SYSTEM =====
class CustomerNotificationSystem {
    constructor() {
        this.notifications = [];
    }

    // Send reservation confirmation
    sendReservationConfirmation(orderData) {
        const notification = {
            type: 'reservation_confirmed',
            orderId: orderData.id,
            timestamp: orderData.timestamp,
            items: orderData.items,
            total: orderData.total,
            nextSteps: [
                'Dirigirse a la tienda para confirmar la reserva',
                'Realizar el depósito de reserva',
                'Esperar confirmación del dueño'
            ]
        };

        this.notifications.push(notification);
        this.logNotification(notification);
        return notification;
    }

    // Send order status update
    sendStatusUpdate(orderId, status, message) {
        const notification = {
            type: 'status_update',
            orderId: orderId,
            status: status,
            message: message,
            timestamp: new Date().toLocaleString('es-AR')
        };

        this.notifications.push(notification);
        console.log(`📢 Actualización de estado para ${orderId}: ${message}`);
        return notification;
    }

    // Log notification
    logNotification(notification) {
        console.group('📧 NOTIFICACIÓN AL CLIENTE');
        console.log('Tipo:', notification.type);
        console.log('ID Reserva:', notification.orderId);
        console.log('Fecha:', notification.timestamp);
        console.log('Total:', `$${notification.total.toLocaleString()}`);
        console.log('Próximos pasos:', notification.nextSteps);
        console.groupEnd();
    }

    // Get all customer notifications
    getNotifications() {
        return this.notifications;
    }

    // Clear notifications
    clear() {
        this.notifications = [];
    }
}

// Initialize customer notification system
const customerNotifications = new CustomerNotificationSystem();

// ===== INTEGRATION WITH MAIN APP =====
// Hook into the order submission process
document.addEventListener('DOMContentLoaded', () => {
    // Override the submitOrder function to include notifications
    const originalSubmitOrder = window.submitOrder;
    
    window.submitOrder = function() {
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

        // Send notifications
        ownerNotifications.sendOrderNotification(orderData);
        customerNotifications.sendReservationConfirmation(orderData);

        // Show customer notification
        showOrderConfirmation(orderData);

        // Clear cart
        cart = [];
        updateCart();
        saveCartToStorage();
    };
});

// ===== DEBUGGING & MONITORING =====
class NotificationMonitor {
    static printStats() {
        console.group('📊 ESTADÍSTICAS DE NOTIFICACIONES');
        console.log('Pedidos pendientes:', ownerNotifications.getPendingOrders().length);
        console.log('Total de pedidos:', ownerNotifications.getOrders().length);
        console.log('Notificaciones al cliente:', customerNotifications.getNotifications().length);
        console.groupEnd();
    }

    static printPendingOrders() {
        const pending = ownerNotifications.getPendingOrders();
        if (pending.length === 0) {
            console.log('No hay pedidos pendientes');
            return;
        }
        console.group('📋 PEDIDOS PENDIENTES');
        pending.forEach(order => {
            console.log(`${order.orderId} - $${order.total.toLocaleString()} - ${order.timestamp}`);
        });
        console.groupEnd();
    }

    static printAllOrders() {
        const orders = ownerNotifications.getOrders();
        if (orders.length === 0) {
            console.log('No hay pedidos registrados');
            return;
        }
        console.group('📦 TODOS LOS PEDIDOS');
        orders.forEach(order => {
            console.log(`${order.orderId} [${order.status}] - $${order.total.toLocaleString()}`);
        });
        console.groupEnd();
    }
}

// ===== CONSOLE COMMANDS FOR TESTING =====
// These are available in the browser console for testing

window.malabisDebug = {
    // Print notification statistics
    stats: () => NotificationMonitor.printStats(),
    
    // Print pending orders
    pending: () => NotificationMonitor.printPendingOrders(),
    
    // Print all orders
    orders: () => NotificationMonitor.printAllOrders(),
    
    // Confirm an order
    confirmOrder: (orderId) => ownerNotifications.confirmOrder(orderId),
    
    // Reject an order
    rejectOrder: (orderId, reason) => ownerNotifications.rejectOrder(orderId, reason),
    
    // Toggle notifications
    toggleNotifications: () => ownerNotifications.toggle(),
    
    // Get owner notifications
    getOwnerNotifications: () => ownerNotifications.getOrders(),
    
    // Get customer notifications
    getCustomerNotifications: () => customerNotifications.getNotifications(),
    
    // Clear all
    clearAll: () => {
        ownerNotifications.orders = [];
        customerNotifications.clear();
        console.log('✅ Todas las notificaciones han sido limpiadas');
    },
    
    // Help
    help: () => {
        console.group('🆘 COMANDOS DISPONIBLES EN MALABIS DEBUG');
        console.log('malabisDebug.stats() - Ver estadísticas');
        console.log('malabisDebug.pending() - Ver pedidos pendientes');
        console.log('malabisDebug.orders() - Ver todos los pedidos');
        console.log('malabisDebug.confirmOrder(orderId) - Confirmar pedido');
        console.log('malabisDebug.rejectOrder(orderId, reason) - Rechazar pedido');
        console.log('malabisDebug.toggleNotifications() - Activar/desactivar notificaciones');
        console.log('malabisDebug.getOwnerNotifications() - Obtener notificaciones del dueño');
        console.log('malabisDebug.getCustomerNotifications() - Obtener notificaciones del cliente');
        console.log('malabisDebug.clearAll() - Limpiar todas las notificaciones');
        console.groupEnd();
    }
};

// Print welcome message
console.log('%c🛍️ MALABIS - Sistema de Notificaciones Activo', 'color: #FF6B6B; font-size: 16px; font-weight: bold;');
console.log('%cEscribe malabisDebug.help() para ver comandos disponibles', 'color: #4ECDC4; font-size: 12px;');