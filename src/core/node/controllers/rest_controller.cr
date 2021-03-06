# Copyright © 2017-2020 The Axentro Core developers
#
# See the LICENSE file at the top-level directory of this distribution
# for licensing information.
#
# Unless otherwise agreed in a custom licensing agreement with the Axentro Core developers,
# no part of this software, including this file, may be copied, modified,
# propagated, or distributed except according to the terms contained in the
# LICENSE file.
#
# Removal or modification of this copyright notice is prohibited.

module ::Axentro::Core::Controllers
  #
  # REST controller version 1.
  #
  # --- blockchain
  #
  # [GET] api/v1/blockchain                               | full blockchain
  # [GET] api/v1/blockchain/header                        | blockchain headers
  # [GET] api/v1/blockchain/size                          | blockchain size
  #
  # --- block
  #
  # [GET] api/v1/block/{:index}                           | full block at index
  # [GET] api/v1/block/{:index}/header                    | block header at index
  # [GET] api/v1/block/{:index}/transactions              | transactions in block
  #
  # --- transaction
  #
  # [GET] api/v1/transaction/{:id}                        | transaction for supplied txn id
  # [GET] api/v1/transaction/{:id}/block                  | full block containing txn id
  # [GET] api/v1/transaction/{:id}/block/header           | block header containing txn id
  # [GET] api/v1/transaction/fees                         | fees
  # [POST] api/v1/transaction                             | create and broadcast a transaction
  # [POST] api/v1/transaction/unsigned                    | create an unsigned transaction
  #
  # --- address
  #
  # [GET] api/v1/address/{:address}                       | amount for address for all tokens
  # [GET] api/v1/address/{:address}/token/{:token}        | amount for address for the token
  # [GET] api/v1/address/{:address}/transactions          | transactions for address
  #
  # --- domain
  #
  # [GET] api/v1/domain/{:domain}                       | amount for domain for all tokens
  # [GET] api/v1/domain/{:domain}/token/{:token}        | amount for domain for the token
  # [GET] api/v1/domain/{:domain}/transactions          | transactions for domain
  #
  # --- hra
  #
  # [GET] api/v1/hra/sales                              | get all hra's domains for sales
  # [GET] api/v1/hra/{:domain}                          | get the status of the domain
  # [GET] api/v1/hra/lookup/{:address}                  | get the domains for an address
  #
  class RESTController
    def initialize(@blockchain : Blockchain)
    end

    def node
      @blockchain.node
    end

    def get_handler
      get "/api/v1/blockchain" { |context, params| __v1_blockchain(context, params) }
      get "/api/v1/blockchain/header" { |context, params| __v1_blockchain_header(context, params) }
      get "/api/v1/blockchain/size" { |context, params| __v1_blockchain_size(context, params) }
      get "/api/v1/block/:index" { |context, params| __v1_block_index(context, params) }
      get "/api/v1/block/:index/header" { |context, params| __v1_block_index_header(context, params) }
      get "/api/v1/block/:index/transactions" { |context, params| __v1_block_index_transactions(context, params) }
      get "/api/v1/transactions" { |context, params| __v1_transactions(context, params) }
      get "/api/v1/transaction/:id" { |context, params| __v1_transaction_id(context, params) }
      get "/api/v1/transaction/:id/block" { |context, params| __v1_transaction_id_block(context, params) }
      get "/api/v1/transaction/:id/block/header" { |context, params| __v1_transaction_id_block_header(context, params) }
      get "/api/v1/transaction/fees" { |context, params| __v1_transaction_fees(context, params) }
      get "/api/v1/address/:address" { |context, params| __v1_address(context, params) }
      get "/api/v1/address/:address/token/:token" { |context, params| __v1_address_token(context, params) }
      get "/api/v1/address/:address/transactions" { |context, params| __v1_address_transactions(context, params) }
      get "/api/v1/domain/:domain" { |context, params| __v1_domain(context, params) }
      get "/api/v1/domain/:domain/token/:token" { |context, params| __v1_domain_token(context, params) }
      get "/api/v1/domain/:domain/transactions" { |context, params| __v1_domain_transactions(context, params) }
      get "/api/v1/hra/sales" { |context, params| __v1_hra_sales(context, params) }
      get "/api/v1/hra/:domain" { |context, params| __v1_hra(context, params) }
      get "/api/v1/hra/lookup/:address" { |context, params| __v1_hra_lookup(context, params) }
      get "/api/v1/tokens" { |context, params| __v1_tokens(context, params) }
      get "/api/v1/nodes" { |context, params| __v1_nodes(context, params) }
      get "/api/v1/node" { |context, params| __v1_node(context, params) }
      get "/api/v1/node/:id" { |context, params| __v1_node_id(context, params) }
      get "/api/v1/node/address/:address" { |context, params| __v1_node_address(context, params) }
      get "/api/v1/node/official_nodes" { |context, params| __v1_official_nodes(context, params) }

      post "/api/v1/transaction" { |context, params| __v1_transaction(context, params) }
      post "/api/v1/transaction/unsigned" { |context, params| __v1_transaction_unsigned(context, params) }

      # post "/api/v1/transaction/send_token" { |context, params| __v1_transaction_send_token(context, params) }
      post "/api/v1/transaction/send_token/unsigned" { |context, params| __v1_transaction_send_token_unsigned(context, params) }

      get "/api/v1/wallet/:address" { |context, params| __v1_wallet(context, params) }
      get "/api/v1/search/:term" { |context, params| __v1_search(context, params) }

      get "/api/v1/nonces/:address/:block_id" { |context, params| __v1_nonces(context, params) }
      get "/api/v1/nonces/pending/:address" { |context, params| __v1_pending_nonces(context, params) }

      get "/api/v1/mining/pending_block" { |context, params| __v1_pending_block(context, params) }

      route_handler
    end

    def __v1_pending_block(context, params)
      with_response(context) do
        @blockchain.mining_block
      end
    end

    def __v1_blockchain(context, params)
      with_response(context) do |query_params|
        page, per_page, direction, sort_field = paginated(query_params)
        @blockchain.blockchain_info.blockchain_impl(false, page, per_page, direction, sort_field)
      end
    end

    def __v1_blockchain_header(context, params)
      with_response(context) do |query_params|
        page, per_page, direction, sort_field = paginated(query_params)
        @blockchain.blockchain_info.blockchain_impl(true, page, per_page, direction, sort_field)
      end
    end

    def __v1_blockchain_size(context, params)
      with_response(context) do
        @blockchain.blockchain_info.blockchain_size_impl
      end
    end

    def __v1_block_index(context, params)
      with_response(context) do
        index = params["index"].to_i64
        @blockchain.blockchain_info.block_index_impl(false, index)
      end
    end

    def __v1_block_index_header(context, params)
      with_response(context) do
        index = params["index"].to_i64
        @blockchain.blockchain_info.block_index_impl(true, index)
      end
    end

    def __v1_block_index_transactions(context, params)
      with_response(context) do |query_params|
        index = params["index"].to_i64
        page, per_page, direction, sort_field = paginated(query_params)
        @blockchain.blockchain_info.transactions_index_impl(index, page, per_page, direction, sort_field)
      end
    end

    def __v1_transactions(context, params)
      with_response(context) do |query_params|
        page, per_page, direction, sort_field = paginated(query_params)
        actions = query_params["actions"]?.try &.split(",") || [] of String
        @blockchain.blockchain_info.transactions_all_impl(page, per_page, direction, sort_field, actions)
      end
    end

    def __v1_transaction_id(context, params)
      with_response(context) do
        id = params["id"]
        @blockchain.indices.transaction_impl(id)
      end
    end

    def __v1_transaction_id_block(context, params)
      with_response(context) do
        id = params["id"]
        @blockchain.blockchain_info.block_transaction_impl(false, id)
      end
    end

    def __v1_transaction_id_block_header(context, params)
      with_response(context) do
        id = params["id"]
        @blockchain.blockchain_info.block_transaction_impl(true, id)
      end
    end

    def __v1_transaction_fees(context, params)
      with_response(context) do
        @blockchain.fees.fees_impl
      end
    end

    def __v1_transaction(context, params)
      with_response(context) do
        json = parse_body(context)

        @blockchain.transaction_creator.create_transaction_impl(
          Core::Transaction.from_json(json["transaction"].to_json)
        )
      end
    end

    def __v1_transaction_unsigned(context, params)
      with_response(context) do
        json = parse_body(context)

        @blockchain.transaction_creator.create_unsigned_transaction_impl(
          json["action"].as_s,
          SendersDecimal.from_json(json["senders"].to_json),
          RecipientsDecimal.from_json(json["recipients"].to_json),
          json["message"].as_s,
          json["token"].as_s,
          TransactionKind.parse(json["kind"].as_s),
          TransactionVersion.parse(json["version"].as_s)
        )
      end
    end

    def __v1_transaction_send_token_unsigned(context, params)
      with_response(context) do
        json = parse_body(context)
        to_address = json["to_address"].as_s
        from_address = json["from_address"].as_s
        amount = json["amount"].as_s
        fee = json["fee"].as_s
        kind = TransactionKind.parse(json["kind"].as_s)
        public_key = json["public_key"].as_s

        @blockchain.transaction_creator.create_unsigned_send_token_impl(
          to_address,
          from_address,
          amount,
          fee,
          kind,
          public_key)
      end
    end

    def __v1_address_transactions(context, params)
      with_response(context) do |query_params|
        page, per_page, direction, sort_field = paginated(query_params)
        actions = query_params["actions"]?.try &.split(",") || [] of String
        address = params["address"]

        @blockchain.blockchain_info.transactions_address_impl(address, page, per_page, direction, sort_field, actions)
      end
    end

    def __v1_address(context, params)
      with_response(context) do
        address = params["address"]
        @blockchain.utxo.amount_impl(address, "all")
      end
    end

    def __v1_address_token(context, params)
      with_response(context) do
        address = params["address"]
        token = params["token"]
        @blockchain.utxo.amount_impl(address, token)
      end
    end

    def __v1_domain_transactions(context, params)
      with_response(context) do |query_params|
        page, per_page, direction, sort_field = paginated(query_params)
        actions = query_params["actions"]?.try &.split(",") || [] of String

        domain = params["domain"]
        address = convert_domain_to_address(domain)
        @blockchain.blockchain_info.transactions_address_impl(address, page, per_page, direction, sort_field, actions)
      end
    end

    def __v1_domain(context, params)
      with_response(context) do
        domain = params["domain"]
        address = convert_domain_to_address(domain)
        @blockchain.utxo.amount_impl(address, "all")
      end
    end

    def __v1_domain_token(context, params)
      with_response(context) do
        domain = params["domain"]
        token = params["token"]
        address = convert_domain_to_address(domain)
        @blockchain.utxo.amount_impl(address, token)
      end
    end

    def __v1_hra_sales(context, params)
      with_response(context) do
        @blockchain.hra.hra_for_sale_impl
      end
    end

    def __v1_hra(context, params)
      domain = params["domain"]

      with_response(context) do
        @blockchain.hra.hra_resolve_impl(domain)
      end
    end

    def __v1_hra_lookup(context, params)
      address = params["address"]

      with_response(context) do |_|
        @blockchain.hra.hra_lookup_impl(address)
      end
    end

    def __v1_tokens(context, params)
      with_response(context) do |query_params|
        page, per_page, direction, _ = paginated(query_params)
        @blockchain.token.tokens_list_impl(page, per_page, direction)
      end
    end

    def __v1_nodes(context, params)
      with_response(context) do
        @blockchain.node_info.nodes_impl
      end
    end

    def __v1_node(context, params)
      with_response(context) do
        @blockchain.node_info.node_impl
      end
    end

    def __v1_node_id(context, params)
      id = params["id"]

      with_response(context) do
        @blockchain.node_info.node_id_impl(id)
      end
    end

    def __v1_node_address(context, params)
      address = params["address"]

      with_response(context) do
        @blockchain.node_info.node_address_impl(address)
      end
    end

    def __v1_official_nodes(context, params)
      with_response(context) do
        @blockchain.node_info.official_nodes_impl
      end
    end

    def __v1_wallet(context, params)
      with_response(context) do |_|
        address_or_domain = params["address"].to_s
        address = address_or_domain
        if address.ends_with?(".ax")
          domain_name = address_or_domain
          result = @blockchain.database.get_domain_map_for(domain_name)[domain_name]?
          if result
            address = result[:address]
          end
        end
        @blockchain.wallet_info.wallet_info_impl(address)
      end
    end

    def __v1_nonces(context, params)
      with_response(context) do
        block_id = params["block_id"].to_i64
        address_or_domain = params["address"].to_s
        address = address_or_domain
        if address.ends_with?(".ax")
          domain_name = address_or_domain
          result = @blockchain.database.get_domain_map_for(domain_name)[domain_name]?
          if result
            address = result[:address]
          end
        end
        @blockchain.nonce_info.nonces_impl(address, block_id)
      end
    end

    def __v1_pending_nonces(context, params)
      with_response(context) do
        address_or_domain = params["address"].to_s
        address = address_or_domain
        if address.ends_with?(".ax")
          domain_name = address_or_domain
          result = @blockchain.database.get_domain_map_for(domain_name)[domain_name]?
          if result
            address = result[:address]
          end
        end
        @blockchain.nonce_info.pending_nonces_impl(address)
      end
    end

    def __v1_search(context, params)
      with_response(context) do
        term = params["term"].to_s
        search_by_term(term)
      end
    end

    # ameba:disable Metrics/CyclomaticComplexity
    private def search_by_term(term : String)
      if term.ends_with?(".ax")
        if @blockchain.database.search_domain(term)
          {found: true, category: "domain", api_urls: ["/api/v1/domain/#{term}"], term: term}
        else
          {found: false, category: "", api_urls: [] of String, term: term}
        end
      elsif is_address?(term)
        if @blockchain.database.search_address(term)
          {found: true, category: "address", api_urls: ["/api/v1/address/#{term}"], term: term}
        else
          {found: false, category: "", api_urls: [] of String, term: term}
        end
      elsif term.size > 0 && !term.scan(/\D/).empty?
        if @blockchain.database.search_transaction(term)
          {found: true, category: "transaction", api_urls: ["/api/v1/transaction/#{term}"], term: term}
        else
          {found: false, category: "", api_urls: [] of String, term: term}
        end
      elsif term.size > 0 && term.scan(/\D/).empty?
        if @blockchain.database.search_block(term)
          {found: true, category: "block", api_urls: ["/api/v1/block/#{term}"], term: term}
        else
          {found: false, category: "", api_urls: [] of String, term: term}
        end
      else
        {found: false, category: "", api_urls: [] of String, term: term}
      end
    end

    private def is_address?(term : String) : Bool
      Address.is_valid?(term)
    end

    private def with_response(context, &block)
      query_params = HTTP::Params.parse(context.request.query || "")

      context.response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
      context.response.headers["Access-Control-Allow-Origin"] = "*"
      context.response.headers["Access-Control-Allow-Headers"] =
        "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
      context.response.print api_success(yield query_params)
      context
    rescue e : Exception
      rest_error(context, e)
    end

    private def rest_error(context, e : Exception)
      error_message = if message = e.message
                        message
                      else
                        "unknown error"
                      end

      context.response.print api_error(error_message)
      context
    end

    private def parse_body(context) : JSON::Any
      raise "empty body" unless body = context.request.body
      raise "empty payload" unless payload = body.gets

      JSON.parse(payload)
    end

    private def convert_domain_to_address(domain : String) : String
      resolved = @blockchain.hra.hra_resolve_impl(domain)
      raise "the domain #{domain} is not resolved" unless resolved[:resolved]

      resolved[:domain][:address]
    end

    include Router
    include NodeComponents::APIFormat
    include NodeComponents::APIParams
    include TransactionModels
  end
end
