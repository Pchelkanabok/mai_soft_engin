workspace {
    name "Travel companion search service"
    !identifiers hierarchical

    model {
        user = person "Пользователь""""c1,c2"
       
        #viewer = person "Зритель конференции""""c1,c2"

        #conf_manager = person "Организатор конференции""""c1,c2"
        
        conf_app = softwareSystem "Сайт конференций" {
            tags 'c1,c2,c3,c4'
            description "Приложение для организации и управлния конференциями"

            Database_conf = container "DataBase_conf" {
                tags "Database,c2" 
                technology "NoSQL Database"

                description "Хранит таблицы конференций, справочные таблицы и информацию об учатсвующих докладах"
            }
            conf_API = container "API сервиса конференций"{
                tags "c2"
                technology "Python FastAPI"

                description "Предоставляет функционал сервиса конференций через API"

                -> Database_conf "Чтение и запись""NoSQL" "c2"
                
            }


            Database_report = container "DataBase_report" {
                tags "Database,c2" 
                technology "NoSQL Database"

                description "Хранит таблицы докладов, справочные таблицы докладов"
            }
            report_service_API = container "API сервиса  резмещения докладов" {
                description "Отвечает за размещение, оценку и публикацию докладов"
                tags "c2"
                technology "Python FastAPI"

                description "Предоставляет функционал сервиса докладов через API"

                -> Database_report "Чтение и запись""NoSQL" "c2"
            }


            Database_auth = container "DataBase_auth" {
                tags "Database,c2" 
                technology "PostgreSQL Database"

                description "Хранит систему данных логинов и паролей"
            }
            auth_service_API = container "API сервиса авторизации" {
                description "Отвечает за регистрацию, авторизацию и валидацию токенов"
                tags "c2"
                technology "Python FastAPI"

                description "Предоставляет функционал сервиса аунтификация через API"

                -> Database_auth "Чтение и запись" "SQL/TCP" "c2"

                database_controller = component "Контроллер обращения к базе"{
                    
                    technology "Python"
                
                    description "Управляет подключением к базе данных и генерацией запросов"
                    -> Database_auth "читает и сохраняет" "SQL/TCP"
                }
                
                auth_controller = component "Контроллер аутентификации"{
                    
                    technology "Python FastAPI"
                
                    description "Возвращает токен при аутентификации, сохраняет шифрованный пароль в базу при регистрации"

                    -> database_controller "AUTH_INFO"
                }
                
            }
            

            Database_user = container "DataBase_user" {
                tags "Database,c2" 
                technology "PostgreSQL Database"

                description "Хранит данные о пользоваьтелях"
            }
            
            user_service_API = container "API сервиса  управления пользователями" {
                description "Отвечает за действия с информацией о пользователях"
                tags "c2"
                technology "Python FastAPI"

                description "Предоставляет функционал сервиса аунтификация через API"

                -> Database_user "Чтение и запись" "SQL/TCP" "c2"
                -> auth_service_API "Валидирует токен" "JSON/HTTPS" "c2"

                database_controller = component "Контроллер обращения к базе" {
                    
                    technology "Python"
                
                    description "Управляет подключением к базе данных и генерацией запросов"
                    -> Database_user "читает и сохраняет" "SQL/TCP"
                }

                auth_controller = component "Контроллер авторизации" {
                    
                    technology "Python"
                
                    description "Ходит в сервис авторизации за проверкой токена"
                    -> auth_service_API "Валидирует токен"
                }
                
                users_controller = component "Контроллер пользователей"{
                    
                    technology "Python FastAPI"
                
                    description "CRUD операции с пользователями"

                    -> database_controller "USER_INFO"
                    -> auth_service_API "Регистрирует/валидирует токен" "JSON/HTTPS"
                    -> auth_controller "token" 
                }


            }

        }


        #conf_manager -> conf_app "Создать конференцию" """c1,c2"
        user -> conf_app "Использует прилдожения для участия в конферениях или их создания""""c1,c2"
        #viewer -> conf_app "Регестрация на созданную конференцию как слушатель""""c1,c2"
        user -> conf_app.conf_API "Получает услугу регистрации на созданную конференцию как докладчикпо средствами API"
        user -> conf_app.user_service_API "Регистрируется, получает список пользователей"
        user -> conf_app.auth_service_API "Получает токен"

        


        conf_app.conf_API -> conf_app.auth_service_API "Валидирует токен""JSON/HTTPS""c2"
        conf_app.report_service_API -> conf_app.auth_service_API "Валидирует токен""""c2"

        
        #conf_manager -> conf_app.conf_API "Получает услугу создания конференции по средствами API" "JSON/HTTPS" "c2"
        #viewer -> conf_app.conf_API "Получает услугу регистрации на созданную конференцию как слушательпо средствами API""""c2"
        conf_app.conf_API -> conf_app.user_service_API "Создает API запрос для взаимодействия с пользоателями" "JSON/HTTPS" "c2"
        conf_app.conf_API -> conf_app.report_service_API "Создает API запрос для взаимодействия с докладами" "JSON/HTTPS" "c2"
        
        
        //conf_app.conf_API -> onf_app.auth_service_AP "Создает API запрос для взаимодействия с сервисом авторизации" "JSON/HTTPS" "с2_"


        // speaker -> report_service "Разместить доклад/Запросить доклады""""c1_"
        // viewer -> report_service "Оценить доклад""""c1_"
        // conf_service -> report_service "Валидирует информацию о зарегестрированных докладах""""c1_"



        // auth_service -> user_service "Передает информацию о регистрации""""c1_"
        // report_service -> user_service "Запрашивает информацию о пользоателях""""c1_"
        // conf_service -> user_service "Запрашивает информацию о пользоателях""""c1_"  
        
        // speaker -> conf_service.conf_API "Создает API запрос" "JSON/HTTPS" "с2_"
        // viewer -> conf_service.conf_API "Создает API запрос" "JSON/HTTPS" "с2_"
        // conf_manager -> conf_service.conf_API "Создает API запрос" "JSON/HTTPS" "с2_"
        // conf_service.conf_API -> user_service "Создает API запрос для взаимодействия с пользоателями" "JSON/HTTPS" "с2_"
        // conf_service.conf_API -> report_service "Создает API запрос для взаимодействия с докладами" "JSON/HTTPS" "с2_"
        // conf_service.conf_API -> auth_service "Создает API запрос для взаимодействия с сервисом авторизации" "JSON/HTTPS" "с2_"
    }



    views {

        themes default

        systemContext conf_app "context_conf" {
            include  "relationship.tag==c1" "element.tag==c1"
            autoLayout
        }

        container conf_app "container_conf" {
            include  "relationship.tag==c2" "element.tag==c2"  
            autoLayout
        }

        component conf_app.auth_service_API "c3_auth" {
            include *

            autoLayout
        }

        component conf_app.user_service_API "c3_users" {
            include *

            autoLayout
        }

         component conf_app.conf_API "c3_conf" {
            include *

            autoLayout
        }

        component conf_app.report_service_API "c3_report" {
            include *

            autoLayout
        }
        

        // systemContext conf_service "context_cong" {
        //     include *
        //     autoLayout
        // }

        // systemContext report_service "context_report" {
        //     include *
        //     autoLayout
        // }

        // container conf_service "c2" {
        //     include *
        //     exclude "relationship.tag==c1_"
        //     autoLayout
        // }

        // component conf_service.conf_API "c3" {
        //     include *
        //     exclude "relationship.tag==c1_"
        //     autoLayout
        // }


        styles {
        element "Database" {
            shape Cylinder
            }
        }

    }

   
}