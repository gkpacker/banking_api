# BankingApi [![Actions Status](https://github.com/gkpacker/banking_api/workflows/Elixir%20CI/badge.svg)](https://github.com/gkpacker/banking_api/actions)
## API
The BankingApi docs are hosted on [postman](https://documenter.getpostman.com/view/4048367/TVCjwkrU)

Users can register, sign in, transfer and withdraw money from it.

When an User sign up, he receives R$1000,00.

When withdrawing, the user receives an email. (Only on dev)

Users can't have negative balance.

As an User, you can login on the BackOffice and export a CSV File with all your transactions.

## Gigalixir
This app is hosted on [Gigalixir](https://gkpacker-banking-api.gigalixirapp.com/)

There are already two users with a deposit (our initial credit), a withdraw and a transfer on the database, you can check by logging in with one of them:

```
email: user@bank.com
password: password
```
```
email: another_user@bank.com
password: password
```

## Setting up on your machine
You can setup this project on your machine with the following steps:

```bash
git clone git@github.com:gkpacker/banking_api.git
cd banking_api
cp .env{.sample,}
```
Next, you'll need to set a `SECRET_KEY_BASE` at your `.env`

You can get one by running:
```bash
mix do deps.get, phx.gen.secret
```
> Or use this one, just to speed up: OVZpBvQs9gCFnYZeP63sJtMSwVgE+nqg+4uxGbtqiTfx7vLSGtF9RZJTE/w55Ula

Then, run:
```bash
docker-compose build
docker-compose up web
```
And you're ready to go! 🚀

Check your http://localhost:4000!

## Running tests
You can run BankingApi tests with:

```bash
docker-compose run --rm test
```

Sadly, I didn't figured out how to setup `chromedriver` as a service for integration tests, but as soon as I learn, I'll update this repo!

## Attention Points
I've followed [this article](https://beancount.github.io/docs/the_double_entry_counting_method.html#introduction) to name models, not sure if they're the best, but at least I'm able to share this document in order to facilitate understanding of the domain.

I couldn't find articles about how to record a transfer in the DB to satisfy the [Accounting Equation](https://en.wikipedia.org/wiki/Accounting_equation), so I decided to credit and debit from user's accounts only.

I also was concerned about having a `dependent: :delete_all` on `accounts`, `postings` and `transactions`, because it would mess with other's accounts balance, so I left it as `:do_nothing`.
