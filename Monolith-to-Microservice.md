As for a monolith application, it is a single, unified codebase that contains all of the logic of the application. It possesses one connection to a single database entity.
The app has one deployment unit, which can make it easier to manage in the early stages of development and is better for a small team.
However, as the application grows, it can become difficult to maintain and scale due to its tightly coupled nature.

The solution is a microservices architecture, which breaks down the applications logic into smaller, independent services that can be developed, deployed, and scaled independently. 
Each microservice is responsible for a specific business function and communicates with other services through APIs.

By breaking down the application into smaller services, we get the "components", where each service features a database.

The second obstacle to overcome is the Method call between services. In which case you can use a Message Broker to facilitate communication between services.

A relational DB should be isolated to prevent type coupling between services. Some steps to achieve this include:

Base point of view: Only using separate tables in the same relational db, Same schema, same database, same DB type

1 Level. Use different schemas (e.g. oders.* , users.*) in the same database
2 Level. different databases
3 Level. different database types (e.g., SQL, NoSQL)

https://www.youtube.com/watch?v=5dilYMii9T4
