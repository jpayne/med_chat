# MedChat

A toy app demonstrating a (very basic) telehealth chat application.

To get started:

* Install dependencies by running `mix deps.get`
* Run `mix ecto.create` and `mix ecto.migrate` to create the Postgres database
* Run `mix run priv/repo/seeds.exs` to create some user records
* Then start the server with `mix phx.server` and visit [`localhost:4000`](http://localhost:4000) in two different browser windows

You can choose whether to enter the application as a Patient or an Employee. It doesn't matter which one you choose first. Patients are dropped into the chat immediately. Employees are dropped into the chat immediately *if* a Patient is already waiting. Otherwise, an Employee will wait until a Patient starts a new chat session, at which point the Employee is automatically redirected to the waiting session (it was a convenient excuse to use PubSub).

There is a JSON API and a LiveView app with some basic Tailwind styling (I hadn't used LiveView since 1.0 shipped, so I welcomed the chance). The JSON and LiveView endpoints have very little overlap (the LiveView app only calls the JSON API to download a list of the chat session's messages), but both endpoints are mostly calling the same underlying modules and functions.

Here's the design at a high level:

* Patients and Employees are both Users
* Sessions (as in "chat sessions") belong to a Patient and an Employee
* Employees can leave Sessions (due to a shift change, for example), causing another Employee to be assigned
* Assignments need to be tracked (for many reasons, probably including liability), so there is a schema called...Assignment
* Sessions can have many Messages. Messages belong to a User (Patient or Employee).
* Only a Patient can end a Session, but an Employee can leave one (become unavailable).
* If an Employee leaves a Session, an automatic reassignment to another available Employee is attempted.

For the author, this was an Elixir/Phoenix refamiliarization project undertaken with time constraints (aka Real Life). As such, some (much?) of this code won't be idiomatic. I tried not to rely on AI for code generation, preferring instead to wrestle with the code and only ask the LLM questions when I got stuck.

There are no tests except for a flimsy `api_test.rest` for the JSON endpoints. I know that's gross. It's not who I really am.

Thanks for looking!