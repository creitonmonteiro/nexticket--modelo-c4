workspace  "NexTicket" "Plataforma de venda de ingressos online para shows e eventos" {

    !identifiers hierarchical

    model {
        usuario = person "User" "Cliente, usuário que usa a plataforma"
        ss = softwareSystem "NexTicket" "Plataforma de venda de ingressos online para shows e eventos" {
            cdn = container "Cloud Front" "Cache de conteúdo estático"
            webApp = container "Web Application" "Aplicação Frontend" "Angular + Typescript"{
                tags "SPA"
            }
            loadBalancer = container "load Balancer" "Serviço de balanceamento e distribuição"{
                tags "Amazon Web Services - Load Balancing" "ALB"
            }
            apiGateway = container "Api Gateway" "Roteamento. Autenticação, Rate Limiting"{
                tags "Amazon Web Services - API Gateway"
            }
            
            kubernetesCluster = group "Kubernetes Cluster"{
                searchEvents = container "Search Events Service" "Serviço de busca full text search" "Golang"{
                    searchControllerComp = component "Search Controller" "Trata as requisições HTTP, valida entrada básica, converte JSON <-> e retorna HTTP"
                    
                    searchServiceComp = component "Search Service" "Gerencia as regras de negócio da consulta"
                    
                    searchRepositoryComp = component "Search Repository" "Abstrai o acesso ao Elasticsearch" "Interface"
                }
                
                eventService = container "Event Service" "Serviço de gerenciamento de eventos" "Golang"{
                    eventControllerComp = component "Event Controller" "Trata as requisições HTTP, valida entrada básica, converte JSON <-> e retorna HTTP"
                    
                    eventServiceComp = component "Event Service" "Gerencia o registro, consulta, altera e exclui os eventos"
                    
                    eventRepositoryComp = component "Event Repository" "Carrega dados do Cache, popula o cache e abstrai o acesso ao banco de dados e Executa SQL" "Interface"
                }
                
                inventoryService = container "Inventory Service" "Responsável por: quantidade por setor/lote, hld, disponibilidade em tempo real" "Golang"{
                    inventoryControllerComp = component "Inventory Controller" "Trata as requisições HTTP, valida entrada básica, converte JSON <-> e retorna HTTP"
                    
                    inventoryServiceComp = component "Inventory Service" "Gerencia validação e inserção de registros no cache, consulta e inserção no banco de dados"
                    
                    inventoryRepositoryComp = component "Inventory Repository" "Abstrai o acesso ao banco de dados e ao cache e Executa SQL" "Interface"
                }
                
                bookingService = container "Booking Service" "Serviço de reserva e compra de ticket(s)" "Golang"{
                    bookingControllerComp = component "Booking Controller" "Trata as requisições HTTP, valida entrada básica, converte JSON <-> e retorna HTTP"
                    
                    bookingServiceComp = component "Booking Service" "Gerencia reserva de ticket(s)"
                    
                    bookingRepositoryComp = component "Booking Repository" "Abstrai o acesso ao banco de dados e Executa SQL" "Interface"
                }
                
                user = container "User Service" "Serviço de consulta, registro e atualização de usuário" "Golang"{
                    usuarioController = component "User Controller" "Trata as requisições HTTP, valida entrada básica, converte JSON <-> e retorna HTTP"
                    
                    usuarioService = component "User Service" "Gerencia o registro, consulta, altera e exclui usuário"
                    
                    usuarioRepository = component "User Repository" "Abstrai o acesso ao banco de dados e Executa SQL" "Interface"
                }
            }
            
            elasticSearch = container "Elasticsearch" "Servico de armazenamento e busca Full-text search"{
                tags "Database"
            }
            worker = container "Worker Service" "Serviço de carregamento de dados no Elasticsearch em Golang"
            kafka = container "Kafka" "Serviço de mensageria"
            debezium = container "Debezium" "Serviço de Change Data Capture (CDC)"
            
            cacheBooking = container "Booking TTL hold" "Cache Redis para reserva temporária de tickets"{
                tags "Database"
            }
            dataBase = container "Database Schema" "Armazena informações de eventos, e venda de ingressos" "PostgreSQL" {
                tags "Database" "Amazon Web Services - RDS"
            }
            userDataBase = container "User Database schema" "Armazena informações de usuários" "MongoDB"{
                tags "Database"
            }
            cacheEvent = container "Event Cache" "Cache Redis"{
                tags "Database"
            }
        }
        paymentService = softwareSystem "Payments System" "Processa pagamentos" "Externo"
        emailService = softwareSystem  "Mail Service" "Envia Notificações" "Externo"
        queue = softwareSystem  "Cloudflare Waiting Room" "Serviço de controle de acesso de usuários a aplicação" "Externo"
        
        usuario -> ss.cdn "Usa o sistema" "HTTPS"
        ss.cdn -> ss.webApp "Serve assets estáticos" "HTTPS"
        ss.cdn -> ss.loadBalancer "Roteia chamadas de API (/api/*)" "HTTPS"
        ss.loadBalancer -> ss.apiGateway "Envia usuário para a aplicação" "HTTP ou TCP"
        
        ss.apiGateway -> ss.eventService.eventControllerComp "Realiza busca no" "HTTP/REST"
        ss.apiGateway -> ss.searchEvents.searchControllerComp "Realiza busca no" "HTTP/REST"
        ss.searchEvents.searchRepositoryComp -> ss.elasticSearch "Realiza busca no" "HTTP/REST"
        ss.eventService.eventRepositoryComp -> ss.cacheEvent "Busca dados no" "TCP/IP"
        ss.eventService.eventRepositoryComp -> ss.dataBase "Busca dados no" "TCP/IP"
        ss.eventService.eventServiceComp -> ss.inventoryService.inventoryControllerComp "Consulta disponibilidade" "HTTP/REST"
        ss.inventoryService.inventoryRepositoryComp -> ss.cacheBooking "Valida disponibilidade e realiza reserva no" "TCP/IP"
        ss.inventoryService.inventoryRepositoryComp -> ss.dataBase "Consulta e persiste dados no" "TCP/IP"
        
        ss.debezium -> ss.dataBase "Captura dados do" "WAL"
        ss.debezium -> ss.kafka "Publica dados no" "TCP/IP"
        ss.kafka -> ss.worker "Entrega eventos para" "TCP/IP"
        ss.worker -> ss.elasticSearch "Insere dados no" "HTTP/REST"
        
        ss.apiGateway -> ss.bookingService.bookingControllerComp "Solicita reserva" "HTTP/REST"
        ss.bookingService.bookingServiceComp -> ss.inventoryService.inventoryControllerComp "Solicita reserva e Aplica status ticket Booked" "HTTP/REST"
        ss.bookingService.bookingServiceComp -> paymentService "Solicita pagamento para" "HTTP/REST"
        ss.bookingService.bookingServiceComp -> emailService "Dispara notificação" "HTTP/REST"
        
        ss.apiGateway -> ss.user.usuarioController "Cria, atualiza ou exclui usuário" "HTTP/REST"
        ss.user.usuarioService -> emailService "Envia notificação" "HTTP/REST"
        ss.apiGateway -> queue "Roteia /bookings para fila virtual em alta demanda" "HTTPS"
        
        ss.user.usuarioController -> ss.user.usuarioService "Repassa a requisição tratada"
        ss.user.usuarioService -> ss.user.usuarioRepository "Solicita persistência"
        ss.user.usuarioRepository -> ss.userDataBase "Lê e escreve dados em" "TCP/IP"
        
        ss.searchEvents.searchControllerComp -> ss.searchEvents.searchServiceComp "Repassa a requisição tratada"
        ss.searchEvents.searchServiceComp -> ss.searchEvents.searchRepositoryComp "Solicita consulta"
        
        ss.eventService.eventControllerComp -> ss.eventService.eventServiceComp "Repassa a requisição tratada"
        ss.eventService.eventServiceComp -> ss.eventService.eventRepositoryComp "Solicita persistência"
        
        ss.bookingService.bookingControllerComp -> ss.bookingService.bookingServiceComp "Repassa a requisição tratada"
        ss.bookingService.bookingServiceComp -> ss.bookingService.bookingRepositoryComp "Solicita persistência"
        
        ss.inventoryService.inventoryControllerComp -> ss.inventoryService.inventoryServiceComp "Repassa a requisição tratada"
        ss.inventoryService.inventoryServiceComp -> ss.inventoryService.inventoryRepositoryComp "Solicita persistência ou consulta"
    }

    views {
        systemContext ss "Context" {
            include *
        }
        container ss "Container" {
            include *
        }
        component ss.user "ComponentUser" "Diagrama de Componentes do Serviço de Controle de Usuários" {
            include *
        }
        component ss.searchEvents "ComponentSearchEvents" "Diagrama de Componentes do Serviço de Busca de Eventos Full-text Search" {
            include *
        }
        component ss.eventService "ComponentEventService" "Diagrama de Componentes do Serviço de Controle de Eventos" {
            include *
        }
        component ss.bookingService "ComponentBookingService" "Diagrama de Componentes do Serviço de Reservas e Pagamentos" {
            include *
        }
        component ss.inventoryService "ComponentInventoryService" "Diagrama de Componentes do Serviço de Inventário de Assentos e Reservas" {
            include *
        }

        theme amazon-web-services-2025.07

        styles {
            element "Element" {
                color #f88728
                stroke #f88728
                strokeWidth 7
                shape roundedbox
            }
            element "Person" {
                shape person
            }
            element "Database" {
                shape cylinder
            }
            element "Boundary" {
                strokeWidth 5
            }
            element "Externo"{
                background #999999
                color #ffffff
            }
            relationship "Relationship"{
                thickness 4
            }
            element "SPA"{
                shape WebBrowser
            }
            element "ALB"{
                shape Ellipse
            }
        }
    }

    configuration {
        scope softwaresystem
    }

}