//
//  FilterServiceTests.swift
//  BouncerTests
//
//  Created by Daniel Bernal on 4/13/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//
import XCTest
import Swinject
@testable import Bouncer

class FilterServiceTests: XCTestCase {
    
    private let container = Container()
    var filterService: FilterService?
    let blockedWords = ["uber", "disfruta", "falabella", "exito.com", "retiros", "colpatria", "cabify", "%"]
    let spamMessages = [
        "Uber Eats: Pide el Fried Rice de PF Chang's ahora por solo $27.230! Antes por $38.900 COP! Pide ya disfruta hasta el 30/4/19 :D t.uber.com/AplicaTyC",
        "DANIEL tienes impuestos por pagar?, El cupo disponible de avances lo puedes desembolsar a cuentas Banco Falabella y de otros bancos. Tienes al 09/04/19 un disponible para avances de $ 3.360.000 en tu Tarjeta de Credito CMR Banco Falabella. Mas info aqui http://ma.sv/MTPlDa o llama 0315877771",
        "exito.com: Consigue aquí todo lo que necesitas para tus preparaciones del fin de semana.  Nunca ha sido tan fácil mercar. Visitanos ya http://ma.sv/M33aA",
        "Viajar seguro y comodo en CABIFY es sinonimo del finde perfecto. Tienes 5 viajes con 15% dto en tu app. Hasta 14/04 en categoria Lite. Dto max 1500"
    ]
    let goodMessages = [
        "El codigo que debe usar para hacer su retiro es 810133. Recuerde que cuenta con 1 hora para retirar el dinero. - Hora: 11:48:05",
        "Usted ha ingresado exitosamente a nuestro canal virtual www.davivienda.com - Hora: 11:46:42",
        "Ultrabox te informa: Tu paquete 1107084 ha cambiado su estado a ¿En reparto¿.¡Pronto lo estaras recibiendo!"
    ]

    
    override func setUp() {}
    
    override func tearDown() {}
    
    func testFilterWordListService() {
        
        container.register(FilterService.self) { resolver in
            let wordListService = WordListDummyService(wordList: self.blockedWords)
            return FilterWordListService(wordListService: wordListService)
        }

        filterService = container.resolve(FilterService.self)
        spamMessages.forEach { msg in
            let result = filterService?.isValidMessage(message: msg)
            XCTAssertFalse(result!)
        }
        
        goodMessages.forEach { msg in
            let result = filterService?.isValidMessage(message: msg)
            XCTAssertTrue(result!)
        }
        
        
    }
    
}
