workspace {
    name "Travel companion search service"
    !identifiers hierarchical

    model {
        speaker = person "Докладчик"
       
        viewer = person "Зритель конференции"

        conf_manager = person "Организатор конференции"

        conf_service = softwareSystem "Сервис конференций" {
            description "Формирует конферениции с докладами спикров"

            Database = container "DataBase" {
                tags "Database" 
                technology "NoSQL Database"

                description "Хранит таблицы конференций, справочные таблицы и информацию об учатсвующих докладах"
            }

            conf_API = container "API сервиса конференций"{
                tags "conf_API"
                technology "Python FastAPI"

                description "Предоставляет функционал сервиса конференций через API"

                a = component "da"

                -> Database "Чтение и запись"
                
            }

        }

        report_service = softwareSystem "Сервис резмещения докладов" {
            description "Отвечает за размещение, оценку и публикацию докладов"
        }

        auth_service = softwareSystem "Сервис авторизации" {
            description "Отвечает за регистрацию, авторизацию и валидацию токенов"
        }

        user_service = softwareSystem "Сервис управления пользователями" {
            description "Отвечает за действия с информацией о пользователях"
        }

        conf_manager -> conf_service "Создать конференцию" """c1_"
        speaker -> conf_service "Регестрация на созданную конференцию как докладчик""""c1_"
        viewer -> conf_service "Регестрация на созданную конференцию как слушатель""""c1_"

        speaker -> report_service "Разместить доклад/Запросить доклады""""c1_"
        viewer -> report_service "Оценить доклад""""c1_"
        conf_service -> report_service "Валидирует информацию о зарегестрированных докладах""""c1_"

        speaker -> auth_service "Создает УЗ""""c1_"
        viewer -> auth_service "Создает УЗ""""c1_"
        conf_manager -> auth_service "Создает УЗ""""c1_"
        user_service -> auth_service "Валидирует токен""""c1_"
        conf_service -> auth_service "Валидирует токен""""c1_"
        report_service -> auth_service "Валидирует токен""""c1_"

        auth_service -> user_service "Передает информацию о регистрации""""c1_"
        report_service -> user_service "Запрашивает информацию о пользоателях""""c1_"
        conf_service -> user_service "Запрашивает информацию о пользоателях""""c1_"  
        
        speaker -> conf_service.conf_API "Создает API запрос" "JSON/HTTPS" "с2_"
        viewer -> conf_service.conf_API "Создает API запрос" "JSON/HTTPS" "с2_"
        conf_manager -> conf_service.conf_API "Создает API запрос" "JSON/HTTPS" "с2_"
        conf_service.conf_API -> user_service "Создает API запрос для взаимодействия с пользоателями" "JSON/HTTPS" "с2_"
        conf_service.conf_API -> report_service "Создает API запрос для взаимодействия с докладами" "JSON/HTTPS" "с2_"
        conf_service.conf_API -> auth_service "Создает API запрос для взаимодействия с сервисом авторизации" "JSON/HTTPS" "с2_"
    }



    views {

        themes default

        systemContext conf_service "context_cong" {
            include *
            autoLayout
        }

        systemContext report_service "context_report" {
            include *
            autoLayout
        }

        container conf_service "c2" {
            include *
            exclude "relationship.tag==c1_"
            autoLayout
        }

        component conf_service.conf_API "c3" {
            include *
            exclude "relationship.tag==c1_"
            autoLayout
        }


        styles {
        element "Database" {
            shape Cylinder
            }
        }

    }

   
}