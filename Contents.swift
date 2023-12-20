import Foundation
import XCTest

// Definición de las estructuras de datos
struct Client {
    var name: String
    var age: Int
    var height: Int
}

struct Reservation {
    var uniqueID: Int
    var hotelName: String
    var clients: [Client]
    var duration: Int
    var breakfastOption: Bool
}

enum ReservationError: Error {
    case duplicateID
    case duplicateClient
    case reservationNotFound
}

typealias ClientList = [Client]
typealias ReservationList = [Reservation]

// Clase para gestionar las reservas del hotel
class HotelReservationManager {
    var reservations: ReservationList = []
    var uniqueIDCounter: Int = 1

    let hotelName = "RocíoBall"
    ///Añade una nueva reserva al listado de reservas.

    func addReservation(clients: ClientList, duration: Int, breakfastOption: Bool) throws -> Reservation {
        // Crea una nueva reserva con un ID único y el nombre del hotel por defecto
        let newReservation = Reservation(uniqueID: uniqueIDCounter, hotelName: hotelName, clients: clients, duration: duration, breakfastOption: breakfastOption)
        // Verifica que la reserva es única por ID y clientes
        try validateReservationUniqueness(newReservation)
        // Calcula el precio de la reserva
        let price = calculateReservationPrice(newReservation)

        // Añade la reserva al listado
            reservations.append(newReservation)
                
        // Incrementa el contador de IDs únicos
        uniqueIDCounter += 1

        // Devuelve la reserva creada
        return newReservation
    }
    
    /// Cancela una reserva existente dado su ID.
    func cancelReservation(reservationID: Int) throws {
        // Busca la reserva por su ID
        guard let reservationIndex = reservations.firstIndex(where: { $0.uniqueID == reservationID }) else {
            throw ReservationError.reservationNotFound
        }

        // Elimina la reserva del listado
        reservations.remove(at: reservationIndex)
    }

    /// Devuelve una copia de la lista de todas las reservas actuales.
    var allReservations: ReservationList {
        return reservations
    }
    /// Valida que la nueva reserva sea única por ID y clientes.
    private func validateReservationUniqueness(_ newReservation: Reservation) throws {
        guard !reservations.contains(where: { $0.uniqueID == newReservation.uniqueID }) else {
            throw ReservationError.duplicateID
        }
        // Verifica que ningún cliente esté en otra reserva existente
        for client in newReservation.clients {
            guard !reservations.contains(where: { $0.clients.contains(where: { $0.name == client.name }) }) else {
                throw ReservationError.duplicateClient
            }
        }
    }
    /// Calcula el precio de una reserva según la fórmula dada.
    internal func calculateReservationPrice(_ reservation: Reservation) -> Double {
        let basePrice = 20.0
        let breakfastFactor = reservation.breakfastOption ? 1.25 : 1
        let price = Double(reservation.clients.count) * basePrice * Double(reservation.duration) * breakfastFactor
        return price
    }
}

// Test
func testAddReservation() {
    let manager = HotelReservationManager()
        let clients1 = [Client(name: "Goku", age: 30, height: 175), Client(name: "Vegeta", age: 35, height: 180)]
        let clients2 = [Client(name: "Piccolo", age: 25, height: 190), Client(name: "Gohan", age: 18, height: 175)]

        do {
            // Añade una reserva válida
            let reservation1 = try manager.addReservation(clients: clients1, duration: 3, breakfastOption: true)

            // Intenta añadir la reserva duplicada por ID
            XCTAssertThrowsError(try manager.addReservation(clients: clients2, duration: 5, breakfastOption: false)) { error in
                guard let reservationError = error as? ReservationError else {
                    XCTFail("Se esperaba un error de tipo ReservationError")
                    return
                }
                XCTAssertEqual(reservationError, ReservationError.duplicateID, "Error de tipo inesperado")
            }

            // Intenta añadir una reserva con un cliente ya existente en otra reserva
            XCTAssertThrowsError(try manager.addReservation(clients: clients1, duration: 2, breakfastOption: true)) { error in
                guard let reservationError = error as? ReservationError else {
                    XCTFail("Se esperaba un error de tipo ReservationError")
                    return
                }
                XCTAssertEqual(reservationError, ReservationError.duplicateClient, "Error de tipo inesperado")
            }

            // Asegura que la reserva válida fue añadida correctamente
            XCTAssertTrue(manager.allReservations.contains { $0.uniqueID == reservation1.uniqueID }, "La reserva válida no fue añadida correctamente")
        } catch {
            XCTFail("Error inesperado: \(error)")
        }}

func testCancelReservation() {
    let manager = HotelReservationManager()
        let clients = [Client(name: "Goku", age: 30, height: 175), Client(name: "Vegeta", age: 35, height: 180)]

        do {
            // Añade y luego cancela la reserva existente
            let reservation = try manager.addReservation(clients: clients, duration: 3, breakfastOption: true)
            try manager.cancelReservation(reservationID: reservation.uniqueID)

            // Asegura que la reserva fue cancelada correctamente
            XCTAssertFalse(manager.allReservations.contains { $0.uniqueID == reservation.uniqueID }, "La reserva no fue cancelada correctamente")

            // Intenta cancelar la reserva inexistente
            XCTAssertThrowsError(try manager.cancelReservation(reservationID: 999)) { error in
                guard let reservationError = error as? ReservationError else {
                    XCTFail("Se esperaba un error de tipo ReservationError")
                    return
                }
                XCTAssertEqual(reservationError, ReservationError.reservationNotFound, "Error de tipo inesperado")
            }
        } catch {
            XCTFail("Error inesperado: \(error)")
        }
}

func testReservationPrice() {
    let manager = HotelReservationManager()
        let clients1 = [Client(name: "Goku", age: 30, height: 175), Client(name: "Vegeta", age: 35, height: 180)]
        let clients2 = [Client(name: "Gohan", age: 18, height: 175), Client(name: "Krillin", age: 28, height: 160)]

        do {
            // Añade dos reservas con los mismos parámetros, excepto los nombres de los clientes
            let reservation1 = try manager.addReservation(clients: clients1, duration: 2, breakfastOption: true)
            let reservation2 = try manager.addReservation(clients: clients2, duration: 2, breakfastOption: true)

            // Asegura que ambas reservas tienen el mismo precio
            XCTAssertEqual(manager.calculateReservationPrice(reservation1), manager.calculateReservationPrice(reservation2), "Las reservas no tienen el mismo precio")
        } catch {
            XCTFail("Error inesperado: \(error)")
        }
}



// Ejecuta los test
testAddReservation()
testCancelReservation()
testReservationPrice()


// Ejemplos de reservas para probar
let manager = HotelReservationManager()

// Ejemplo 1: Reserva válida con desayuno para Goku y Vegeta
do {
    let clients1 = [Client(name: "Goku", age: 30, height: 175), Client(name: "Vegeta", age: 35, height: 180)]
    let reservation1 = try manager.addReservation(clients: clients1, duration: 3, breakfastOption: true)
    print("Reserva 1 añadida: \(reservation1)")
} catch {
    print("Error al añadir reserva 1: \(error)")
}

// Ejemplo 2: Intento añadir una reserva duplicada por ID
do {
    let clients2 = [Client(name: "Piccolo", age: 25, height: 190), Client(name: "Gohan", age: 18, height: 175)]
    let reservation2 = try manager.addReservation(clients: clients2, duration: 5, breakfastOption: false)
    print("Reserva 2 añadida: \(reservation2)")
} catch {
    print("Error al añadir reserva 2: \(error)")
}

// Ejemplo 3: Intento de añadir una reserva con cliente ya existente en otra reserva
do {
    let clients3 = [Client(name: "Goku", age: 30, height: 175), Client(name: "Krillin", age: 28, height: 160)]
    let reservation3 = try manager.addReservation(clients: clients3, duration: 2, breakfastOption: true)
    print("Reserva 3 añadida: \(reservation3)")
} catch {
    print("Error al añadir reserva 3: \(error)")
}

// Ejemplo 4: Cancela una reserva existente
do {
    let clients4 = [Client(name: "Vegeta", age: 35, height: 180), Client(name: "Trunks", age: 10, height: 130)]
    let reservation4 = try manager.addReservation(clients: clients4, duration: 4, breakfastOption: false)
    print("Reserva 4 añadida: \(reservation4)")

    // Cancela la reserva 4
    try manager.cancelReservation(reservationID: reservation4.uniqueID)
    print("Reserva 4 cancelada")
} catch {
    print("Error al añadir o cancelar reserva 4: \(error)")
}

// Ejemplo 5: Intento cancelar una reserva inexistente
do {
    // Intenta cancelar una reserva con ID inexistente
    try manager.cancelReservation(reservationID: 999)
    print("Intento de cancelar reserva inexistente")
} catch {
    print("Error al intentar cancelar reserva inexistente: \(error)")
}

// Ejemplo 6: Añado dos reservas con los mismos parámetros excepto los nombres de los clientes
do {
    let clients6a = [Client(name: "Yamcha", age: 28, height: 180), Client(name: "Tien", age: 30, height: 175)]
    let clients6b = [Client(name: "Krillin", age: 28, height: 160), Client(name: "Yamcha", age: 28, height: 180)]

    let reservation6a = try manager.addReservation(clients: clients6a, duration: 2, breakfastOption: true)
    print("Reserva 6a añadida: \(reservation6a)")

    // Intenta añadir una reserva con los mismos parámetros que la 6a
    let reservation6b = try manager.addReservation(clients: clients6b, duration: 2, breakfastOption: true)
    print("Reserva 6b añadida: \(reservation6b)")
} catch {
    print("Error al añadir reservas 6a y 6b: \(error)")
}

// Muestra todas las reservas actuales
print("\nTodas las reservas actuales:")
manager.allReservations.forEach { print($0) }
