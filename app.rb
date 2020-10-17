# require 'sinatra'
# require 'sinatra/reloader'
# require 'sinatra/cookies'
# require 'pry'
# require 'pg'
# require 'digest'

# enable :sessions

# ライブラリの読み込み
require 'digest'  # digestの読み込み
require 'bundler' # bundlerの読み込み
Bundler.require  # Gemfileに書かれているライブラリを一括で読み込み

# 開発環境のみで使用
if development? #書き換える
  require 'sinatra/reloader'
  require 'pry'
end

client = PG::connect(
  :host => ENV.fetch("DB_HOST", "localhost"),
  :user => ENV.fetch("DB_USER"),
  :password => ENV.fetch("DB_PASSWORD"),
  :dbname => ENV.fetch("DB_NAME")
)

get '/' do
  return erb :top
end

get '/signup' do
  return erb :signup
end

post '/signup' do
  name = params[:name]
  email = params[:email]
  password = params[:password]
  client.exec_params(
    "INSERT INTO users (name, email, password) VALUES ($1, $2, $3)",
    [name, email, password]
  )
  user = client.exec_params(
    "SELECT * FROM users WHERE email = $1 AND password = $2",
    [email, password]
  ).to_a.first
  session[:user] = user
  return redirect '/mypage'
end

# get '/login' do
#   return erb :login
# end

post '/login' do
  email = params[:email]
  password = params[:password]
  user = client.exec_params(
    "SELECT * FROM users WHERE email = $1 AND password = $2 LIMIT 1",
    [email, password]
  ).to_a.first
  if user.nil?
    return erb :top
  else
    session[:user] = user
    return redirect '/mypage'
  end
end

delete '/logout' do
  session[:user] = nil
  return redirect '/'
end

get '/mypage' do
  if session[:user].nil?
    return redirect '/login'
  else
    @name = session[:user]['name']
    @incomes = client.exec_params(
      "SELECT * FROM incomes WHERE user_id = $1 ORDER BY date_of_income DESC LIMIT 5",
      [session[:user]['id']]
    ).to_a
    @expenses = client.exec_params(
      "SELECT * FROM expenses WHERE user_id = $1 ORDER BY date_of_expense DESC LIMIT 5 ",
      [session[:user]['id']]
    ).to_a
    #"SELECT * FROM expenses WHERE user_id = #{session[:user]['id']}" 
    #↑エスケープ処理ではなく変数展開で書く場合はこんな感じ
    # binding.pry
    return erb :mypage
  end
end

post '/mypage' do
  income = params[:income]
  income_type = params[:income_type]
  date_of_income = params[:date_of_income]
  user_id = session[:user]['id']
  if !income.nil?
    client.exec_params(
      "INSERT INTO incomes (income, income_type, date_of_income, user_id) VALUES ($1, $2, $3, $4)",
      [income, income_type, date_of_income, user_id]
    )
  end
  expense = params[:expense]
  expense_type = params[:expense_type]
  date_of_expense = params[:date_of_expense]
  user_id = session[:user]['id']
  if !expense.nil?
    client.exec_params(
      "INSERT INTO expenses (expense, expense_type, date_of_expense, user_id) VALUES ($1, $2, $3, $4)",
      [expense, expense_type, date_of_expense, user_id]
    )
  end
  @name = session[:user]['name']
  return redirect '/mypage'
end

put '/mypage' do
  renewal_date_of_income = params[:renewal_date_of_income]
  renewal_income_type = params[:renewal_income_type]
  renewal_income = params[:renewal_income]
  id = params[:current_id]
  client.exec_params(
    "UPDATE incomes SET income = $1, income_type = $2, date_of_income = $3 WHERE id = $4",
    [renewal_income, renewal_income_type, renewal_date_of_income, id]
  )
  renewal_date_of_expense = params[:renewal_date_of_expense]
  renewal_expense_type = params[:renewal_expense_type]
  renewal_expense = params[:renewal_expense]
  # id = params[:current_id]
  client.exec_params(
    "UPDATE expenses SET expense = $1, expense_type = $2, date_of_expense = $3 WHERE id = $4",
    [renewal_expense, renewal_expense_type, renewal_date_of_expense, id]
  )
  @name = session[:user]['name']
  return redirect '/mypage'
end

delete '/mypage' do
  id = params[:current_id]
  client.exec_params(
    "DELETE FROM incomes WHERE id = $1",
    [id]
  )
  client.exec_params(
    "DELETE FROM expenses WHERE id = $1",
    [id]
  )
  return redirect '/mypage'
end

# get '/statistics' do
#   return erb :statistics
# end

# get '/dbop' do
#   dayly_balance_of_payments = params[:dayly_balance_of_payments]
#   @incomes = client.exec_params(
#     "SELECT * FROM incomes WHERE user_id = $1 AND date_of_income::text = $2",
#     [session[:user]['id'],dayly_balance_of_payments]
#   ).to_a
#   @expenses = client.exec_params(
#     "SELECT * FROM expenses WHERE user_id = $1 AND date_of_expense::text = $2",
#     [session[:user]['id'], dayly_balance_of_payments]
#   ).to_a
#   @total_income_by_day = client.exec_params(
#     "SELECT SUM(income) FROM incomes WHERE user_id = $1 AND date_of_income::text = $2",
#      [session[:user]['id'], dayly_balance_of_payments]
#   ).to_a.first #ここかなり手こずった。.to_a.firstしてerbの方でキー指定したら上手く値を取得できた。
#   @total_expenditure_by_day = client.exec_params(
#     "SELECT SUM(expense) FROM expenses WHERE user_id = $1 AND date_of_expense::text = $2",
#      [session[:user]['id'], dayly_balance_of_payments]
#   ).to_a.first
#   # binding.pry
#   def primary_balance
#     @total_income_by_day['sum'].to_i - @total_expenditure_by_day['sum'].to_i
#   end
#   return erb :dbop
# end

get '/mbop' do
  # monthly_balance_of_payments = params[:monthly_balance_of_payments] LIKE節でのエスケープ処理が難しいためコメントアウトしている
  @incomes = client.exec_params(
    "SELECT * FROM incomes WHERE user_id = $1 AND date_of_income::text LIKE '%#{params[:monthly_balance_of_payments]}%' ORDER BY date_of_income ASC",
    [session[:user]['id']]
  ).to_a
  @expenses = client.exec_params(
    "SELECT * FROM expenses WHERE user_id = $1 AND date_of_expense::text LIKE '%#{params[:monthly_balance_of_payments]}%' ORDER BY date_of_expense ASC",
    [session[:user]['id']]
  ).to_a
  @total_income_by_month = client.exec_params(
    "SELECT SUM(income) FROM incomes WHERE user_id = $1 AND date_of_income::text LIKE '%#{params[:monthly_balance_of_payments]}%'",
     [session[:user]['id']]
  ).to_a.first
  @total_expenditure_by_month = client.exec_params(
    "SELECT SUM(expense) FROM expenses WHERE user_id = $1 AND date_of_expense::text LIKE '%#{params[:monthly_balance_of_payments]}%'",
     [session[:user]['id']]
  ).to_a.first
  def primary_balance
    @total_income_by_month['sum'].to_i - @total_expenditure_by_month['sum'].to_i
  end
  # グラフ
  @monthly_incomes_type = client.exec_params(
    "SELECT income_type FROM incomes WHERE user_id = $1 AND date_of_income::text LIKE '%#{params[:monthly_balance_of_payments]}%' GROUP BY income_type ORDER BY SUM(income) DESC",
    [session[:user]['id']]
  ).to_a
  @incomes_type_total = client.exec_params(
    "SELECT SUM(income) FROM incomes WHERE user_id = $1 AND date_of_income::text LIKE '%#{params[:monthly_balance_of_payments]}%' GROUP BY income_type ORDER BY SUM(income) DESC",
    [session[:user]['id']]
  ).to_a
  @monthly_expenses_type = client.exec_params(
    "SELECT expense_type FROM expenses WHERE user_id = $1 AND date_of_expense::text LIKE '%#{params[:monthly_balance_of_payments]}%' GROUP BY expense_type ORDER BY SUM(expense) DESC",
    [session[:user]['id']]
  ).to_a
  @expenses_type_total = client.exec_params(
    "SELECT SUM(expense) FROM expenses WHERE user_id = $1 AND date_of_expense::text LIKE '%#{params[:monthly_balance_of_payments]}%' GROUP BY expense_type ORDER BY SUM(expense) DESC",
    [session[:user]['id']]
  ).to_a
  #ここまで
  return erb :mbop
end

get '/wbop' do
  @start_date = params[:start_date]
  @end_date = params[:end_date]
  @incomes = client.exec_params(
    "SELECT * FROM incomes WHERE user_id = $1 AND date_of_income BETWEEN $2 AND $3 ORDER BY date_of_income ASC",
    [session[:user]['id'], @start_date, @end_date]
  ).to_a
  @expenses = client.exec_params(
    "SELECT * FROM expenses WHERE user_id = $1 AND date_of_expense BETWEEN $2 AND $3 ORDER BY date_of_expense ASC",
    [session[:user]['id'], @start_date, @end_date]
  ).to_a
  @total_income_by_range = client.exec_params(
    "SELECT SUM(income) FROM incomes WHERE user_id = $1 AND date_of_income BETWEEN $2 AND $3",
     [session[:user]['id'], @start_date, @end_date]
  ).to_a.first
  @total_expenditure_by_range = client.exec_params(
    "SELECT SUM(expense) FROM expenses WHERE user_id = $1 AND date_of_expense BETWEEN $2 AND $3",
     [session[:user]['id'], @start_date, @end_date]
  ).to_a.first
  def primary_balance
    @total_income_by_range['sum'].to_i - @total_expenditure_by_range['sum'].to_i
  end
  return erb :wbop
end

put '/wbop' do
  renewal_date_of_income = params[:renewal_date_of_income]
  renewal_income_type = params[:renewal_income_type]
  renewal_income = params[:renewal_income]
  id = params[:current_id]
  client.exec_params(
    "UPDATE incomes SET income = $1, income_type = $2, date_of_income = $3 WHERE id = $4",
    [renewal_income, renewal_income_type, renewal_date_of_income, id]
  )
  renewal_date_of_expense = params[:renewal_date_of_expense]
  renewal_expense_type = params[:renewal_expense_type]
  renewal_expense = params[:renewal_expense]
  # id = params[:current_id]
  client.exec_params(
    "UPDATE expenses SET expense = $1, expense_type = $2, date_of_expense = $3 WHERE id = $4",
    [renewal_expense, renewal_expense_type, renewal_date_of_expense, id]
  )
  @start_date = params[:start_date]
  @end_date = params[:end_date]
  return redirect '/wbop'
end

delete '/wbop' do
  id = params[:current_id]
  client.exec_params(
    "DELETE FROM incomes WHERE id = $1",
    [id]
  )
  client.exec_params(
    "DELETE FROM expenses WHERE id = $1",
    [id]
  )
  return redirect '/wbop'
end