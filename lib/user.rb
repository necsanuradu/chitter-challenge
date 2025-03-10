require './lib/db/connect.rb'
require './lib/string.rb'
require 'uri'
require 'digest/sha1'

class User

  def self.query(query, db_connection = Connect.initiate(:chitter))
    db_connection.exec(query)
  end

  def self.keys_and_values
    @query_keys, @query_values = [], []
  end

  def nth(n)
    return self[[n.to_i, 0].max] unless self.count <= [n.to_i, 0].max
    nil
  end

  def self.not_an_email_address(key, value)
    unless (key.to_s.clean_key.downcase == "email") && (value.to_s =~ URI::MailTo::EMAIL_REGEXP) != 0
      true
    else
      false
    end
  end

  def self.check_key_value_return(value = :NULL, key = :NULL)
    return if key.to_s.clean_key.downcase == "submit"
    value = value.to_s.hash_1 if key.to_s.clean_key.downcase == "password" || key.to_s.clean_key.downcase == "username"
    @query_values << value.to_s.clean_value if not_an_email_address(key, value)
    @query_keys << key.to_s.clean_key
  end

  def self.add(table_column_values_hash = {})
    [keys_and_values, table_column_values_hash.each { |key, value| check_key_value_return(value, key) }]
    return nil if @query_keys.count != @query_values.count || table_column_values_hash.empty?
    users_return = query("INSERT INTO users (#{@query_keys.join(",")}) VALUES (#{@query_values.join(",")}) RETURNING id, username").to_a
    (users_return.nil? || (users_return.count != 1)) ? nil : users_return
  end

  def self.find(user_name)
    [keys_and_values, check_key_value_return(user_name, :username)]
    users_return = query("SELECT * FROM users WHERE username = #{@query_values.first}").to_a
    users_return.map{ |pair| pair.transform_keys(&:to_sym) }
  end

  def self.get(user_name, password)
    [keys_and_values, check_key_value_return(user_name, :username), check_key_value_return(password, :password)]
    users_return = query("SELECT id, username FROM users WHERE username = #{@query_values[-2]} AND password = #{@query_values.last}").to_a
    users_return.map!{ |pair| pair.transform_keys(&:to_sym) }
    (users_return.nil? || (users_return.count != 1)) ? nil : users_return
  end

  def self.delete(user_name)
    [keys_and_values, check_key_value_return(user_name)]
    query("DELETE FROM users WHERE username = #{@query_values.last}")
  end

  def self.all(user_name)
    users_return = query("SELECT * FROM users").to_a
    users_return.map{ |pair| pair.transform_keys(&:to_sym) }
  end

end
