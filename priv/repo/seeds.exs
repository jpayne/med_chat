# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MedChat.Repo.insert!(%MedChat.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias MedChat.Repo
alias MedChat.Account.User

employee_names = Faker.Util.sample_uniq(100, &Faker.Person.En.first_name/0)
Enum.each(employee_names, fn name ->
  Repo.insert!(%User{
    name: "#{name} Employee",
    email: "#{String.downcase(name)}@medchat.example.com",
    is_employee: true,
    status: :unavailable
  })
end)

patient_names = Faker.Util.sample_uniq(100, &Faker.Person.En.first_name/0)
Enum.each(patient_names, fn name ->
  Repo.insert!(%User{
    name: "#{name} Patient",
    email: "#{String.downcase(name)}@google.example.com",
    is_employee: false
  })
end)
