require "./../../spec_helper"
require "./../utils"

include Sushi::Core::Models
include Units::Utils
include Sushi::Core
include Sushi::Common::Num
include Hashes

describe Block do

  it "should create a genesis block (new block with no transactions)" do
    block = Block.new(0_i64, [] of Transaction,  0_u64, "genesis")
    block.index.should eq(0)
    block.transactions.should eq([] of Transaction)
    block.nonce.should eq(0)
    block.prev_hash.should eq("genesis")
    block.merkle_tree_root.should eq("")
  end

  it "should return the header for #to_header" do
    block = Block.new(0_i64, [] of Transaction,  0_u64, "genesis")
    block.to_header.should eq({index: 0_i64, nonce: 0_u64, prev_hash: "genesis", merkle_tree_root: ""})
  end

  describe "#calcluate_merkle_tree_root" do

    it "should return empty merkle tree root value when no transactions" do
      block = Block.new(0_i64, [] of Transaction,  0_u64, "prev_hash")
      block.calcluate_merkle_tree_root.should eq("")
    end

    it "should calculate merkle tree root when coinbase transaction" do
      coinbase_transaction = a_fixed_coinbase_transaction
      block = Block.new(1_i64, [coinbase_transaction],  1_u64, "prev_hash")
      block.calcluate_merkle_tree_root.should eq("9233320dac9af5421ea875977c94afe39c041cdb")
    end

    it "should calculate merkle tree root when 2 transactions (first is coinbase)" do
      coinbase_transaction = a_fixed_coinbase_transaction
      transaction1 = a_fixed_signed_transaction
      block = Block.new(1_i64, [coinbase_transaction, transaction1],  1_u64, "prev_hash")
      block.calcluate_merkle_tree_root.should eq("c3e8b4726fb6165fbb7f143a85c8e645f7e33724")
    end

  end

  describe "#valid_nonce?" do

    it "should return true when valid" do
      coinbase_transaction = a_fixed_coinbase_transaction
      block = Block.new(1_i64, [coinbase_transaction],  1_u64, "08101ac35b72e68db9670e1afc6b4566bc99a2c7df2772f6c03d18d39a3a5dce")
      block.valid_nonce?(281_u64, 2).should be_true
    end

    it "should return false when invalid" do
      coinbase_transaction = a_fixed_coinbase_transaction
      block = Block.new(1_i64, [coinbase_transaction],  1_u64, "prev_hash")
      block.valid_nonce?(1_u64).should be_false
    end
  end

  describe "#valid_as_latest?" do

    context "when not a genesis block" do

      it "should be valid" do
        blockchain = Blockchain.new(a_fixed_sender_wallet)
        prev_hash = blockchain.chain[0].to_hash
        coinbase_transaction = a_fixed_coinbase_transaction
        block = Block.new(1_i64, [coinbase_transaction],  60127_u64, prev_hash)
        block.valid_as_latest?(blockchain).should be_true
      end

      it "should raise an error: Invalid index" do
        blockchain = Blockchain.new(a_fixed_sender_wallet)
        prev_hash = blockchain.chain[0].to_hash
        block = Block.new(2_i64, [a_fixed_signed_transaction],  0_u64, prev_hash)
        expect_raises(Exception, "Invalid index, 2 have to be 1") do
          block.valid_as_latest?(blockchain)
        end
      end

      it "should raise an error: Invalid transaction" do
        blockchain = Blockchain.new(a_fixed_sender_wallet)
        prev_hash = blockchain.chain[0].to_hash
        block = Block.new(1_i64, [a_fixed_signed_transaction],  0_u64, prev_hash)
        expect_raises(Exception, "actions has to be 'head' for coinbase transaction") do
          block.valid_as_latest?(blockchain)
        end
      end

    end

    context "when a genesis block" do

      it "should be valid" do
        blockchain = Blockchain.new(a_fixed_sender_wallet)
        block = Block.new(0_i64, [] of Transaction,  0_u64, "genesis")
        block.valid_as_latest?(blockchain).should be_true
      end

      it "should raise an error: Transactions have to be empty" do
        blockchain = Blockchain.new(a_fixed_sender_wallet)
        block = Block.new(0_i64, [a_fixed_signed_transaction],  0_u64, "genesis")
        expect_raises(Exception, /Transactions have to be empty for genesis block/) do
          block.valid_as_latest?(blockchain)
        end
      end

      it "should raise an error: nonce has to be '0'" do
        blockchain = Blockchain.new(a_fixed_sender_wallet)
        block = Block.new(0_i64, [] of Transaction,  1_u64, "genesis")
        expect_raises(Exception, "nonce has to be '0' for genesis block: 1") do
          block.valid_as_latest?(blockchain)
        end
      end

      it "should raise an error: prev_hash has to be 'genesis'" do
        blockchain = Blockchain.new(a_fixed_sender_wallet)
        block = Block.new(0_i64, [] of Transaction,  0_u64, "not-genesis")
        expect_raises(Exception, "prev_hash has to be 'genesis' for genesis block: not-genesis") do
          block.valid_as_latest?(blockchain)
        end
      end

    end

  end

  describe "#valid_for?" do

    it "should return true when valid" do
      prev_block = block_101
      prev_hash = prev_block.to_hash
      block = block_102
      block.valid_for?(prev_block)
    end

    it "should raise an error: mismatch index" do
      transaction1 = a_fixed_signed_transaction
      prev_block = Block.new(3_i64, [transaction1],  0_u64, "prev_hash_1")
      prev_hash = prev_block.to_hash
      block = Block.new(2_i64, [transaction1],  0_u64, prev_hash)
      expect_raises(Exception, "Mismatch index for the prev block(3): 2") do
        block.valid_for?(prev_block)
      end
    end

    it "should raise an error: prev_hash does not match" do
      transaction1 = a_fixed_signed_transaction
      prev_block = Block.new(1_i64, [transaction1],  0_u64, "prev_hash_1")
      prev_hash = prev_block.to_hash
      block = Block.new(2_i64, [transaction1],  0_u64, "incorrect_prev_hash")
      expect_raises(Exception, "prev_hash is invalid: #{prev_hash} != incorrect_prev_hash") do
        block.valid_for?(prev_block)
      end
    end

    it "should raise an error: nonce is invalid" do
      transaction1 = a_fixed_signed_transaction
      prev_block = Block.new(1_i64, [transaction1],  0_u64, "prev_hash_1")
      prev_hash = prev_block.to_hash
      block = Block.new(2_i64, [transaction1],  0_u64, prev_hash)
      expect_raises(Exception, "The nonce is invalid: 0") do
        block.valid_for?(prev_block)
      end
    end

    it "should raise an error: Invalid merkle tree root" do
      # someone changed the amount from 3145.161290322581 to 13145.161290322581
      # between block_102 and block_102_invalid
      block_102.valid_for?(block_101).should eq(true)

      expect_raises(Exception, "Invalid merkle tree root: #{block_102_invalid.calcluate_merkle_tree_root} != #{block_102.merkle_tree_root}") do
        block_102_invalid.valid_for?(block_101)
      end
    end

  end

  describe "#calculate_utxo" do

    it "should unspent transactions" do
      r1_address = block_101.transactions.first.recipients.first[:address]
      r1_amount = prec(block_101.transactions.first.recipients.first[:amount])
      r2_address = block_101.transactions.first.recipients[1][:address]
      r2_amount = prec(block_101.transactions.first.recipients[1][:amount])
      r3_address = block_101.transactions.first.recipients[2][:address]
      r3_amount = prec(block_101.transactions.first.recipients[2][:amount])
      transaction_id = block_101.transactions.first.id

      expected_utxo = {utxo: {r1_address => r1_amount,
                              r2_address => r2_amount,
                              r3_address => r3_amount},
                       indices: {transaction_id => block_101.index}}

      block_101.calculate_utxo.should eq(expected_utxo)
    end

  end

  describe "#find_transaction" do

    it "should find a transaction when an matching one exists" do
      coinbase_transaction = a_fixed_coinbase_transaction
      block = Block.new(1_i64, [coinbase_transaction, a_fixed_signed_transaction],  0_u64, "prev_hash_1")
      block.find_transaction(coinbase_transaction.id).should eq(coinbase_transaction)
    end

    it "should return nil when cannot find a matching transaction" do
      coinbase_transaction = a_fixed_coinbase_transaction
      block = Block.new(1_i64, [coinbase_transaction, a_fixed_signed_transaction],  0_u64, "prev_hash_1")
      block.find_transaction("transaction-not-found").should be_nil
    end

  end

end

def block_101
  Block.from_json(%({"index":101,"transactions":[{"id":"4db42cdfcffc85c86734dc1bc00adcc21aae274a3137d6a16a31162a8d6ea7b2","action":"head","senders":[],"recipients":[{"address":"VDAyYTVjMDYwZjYyZThkOWM5ODhkZGFkMmM3NzM2MjczZWZhZjIxNDAyN\
WRmNWQ0","amount":4166.666666666667},{"address":"VDBhYTYxYzk5MTQ4M2QyZmU1YTA4NzUxZjYzYWUzYzA4ZTExYTgzMjdkNWViODU2","amount":3333.333333333333},{"address":"VDAyNTk0YjdlMTc4N2FkODRmYTU0YWZmODM1YzQzOTA2YTEzY2NjYmMyNjdkYjVm","amount":2500.0}\
],"message":"0","prev_hash":"0","sign_r":"0","sign_s":"0"}],"nonce":1441005721641889293,"prev_hash":"08101ac35b72e68db9670e1afc6b4566bc99a2c7df2772f6c03d18d39a3a5dce","merkle_tree_root":"9233320dac9af5421ea875977c94afe39c041cdb"}))
end

def block_102
  Block.from_json(%({"index":102,"transactions":[{"id":"8577698f8e411c4d8449535f716caad50e44d72a5c5561d5d2abde9229d1e402","action":"head","senders":[],"recipients":[{"address":"VDAyYTVjMDYwZjYyZThkOWM5ODhkZGFkMmM3NzM2MjczZWZhZjIxNDAyN\
WRmNWQ0","amount":3145.161290322581},{"address":"VDBhYTYxYzk5MTQ4M2QyZmU1YTA4NzUxZjYzYWUzYzA4ZTExYTgzMjdkNWViODU2","amount":4354.8387096774195},{"address":"VDAyNTk0YjdlMTc4N2FkODRmYTU0YWZmODM1YzQzOTA2YTEzY2NjYmMyNjdkYjVm","amount":2500.0\
}],"message":"0","prev_hash":"0","sign_r":"0","sign_s":"0"}],"nonce":220767039727821713,"prev_hash":"dca74fb6b6b3d9ba3e007341ac367aae2503ef1d196676e52c1a1e14fe096007","merkle_tree_root":"710e1c4174d35d2df5df71ca257815013c5d00c8"}))
end

def block_102_invalid
  Block.from_json(%({"index":102,"transactions":[{"id":"8577698f8e411c4d8449535f716caad50e44d72a5c5561d5d2abde9229d1e402","action":"head","senders":[],"recipients":[{"address":"VDAyYTVjMDYwZjYyZThkOWM5ODhkZGFkMmM3NzM2MjczZWZhZjIxND\
AyNWRmNWQ0","amount":13145.161290322581},{"address":"VDBhYTYxYzk5MTQ4M2QyZmU1YTA4NzUxZjYzYWUzYzA4ZTExYTgzMjdkNWViODU2","amount":4354.8387096774195},{"address":"VDAyNTk0YjdlMTc4N2FkODRmYTU0YWZmODM1YzQzOTA2YTEzY2NjYmMyNjdkYjVm","amount":25\
00.0}],"message":"0","prev_hash":"0","sign_r":"0","sign_s":"0"}],"nonce":220767039727821713,"prev_hash":"dca74fb6b6b3d9ba3e007341ac367aae2503ef1d196676e52c1a1e14fe096007","merkle_tree_root":"710e1c4174d35d2df5df71ca257815013c5d00c8"}))
end

def a_fixed_coinbase_transaction

  recipient1 = a_recipient_with_address("VDAyYTVjMDYwZjYyZThkOWM5ODhkZGFkMmM3NzM2MjczZWZhZjIxNDAyNWRmNWQ0", 4166.666666666667)
  recipient2 = a_recipient_with_address("VDBhYTYxYzk5MTQ4M2QyZmU1YTA4NzUxZjYzYWUzYzA4ZTExYTgzMjdkNWViODU2", 3333.333333333333)
  recipient3 = a_recipient_with_address("VDAyNTk0YjdlMTc4N2FkODRmYTU0YWZmODM1YzQzOTA2YTEzY2NjYmMyNjdkYjVm", 2500.0)

  Transaction.new(
    "4db42cdfcffc85c86734dc1bc00adcc21aae274a3137d6a16a31162a8d6ea7b2",
    "head", # action
    [] of Sender,
    [ recipient1, recipient2, recipient3],
    "0", # message
    "0", # prev_hash
    "0", # sign_r
    "0", # sign_s
  )

 # prev_hash = 08101ac35b72e68db9670e1afc6b4566bc99a2c7df2772f6c03d18d39a3a5dce
 # nonce = 1441005721641889293
end


def a_recipient_with_address(address : String, amount : Float64)
  {address: address,
    amount: amount}
end

def a_fixed_sender_wallet
  Wallet.new("ODI1MTY3NzY2NTA2NTYyMjQwNTM3NjM3NTQ1NjEzMTIyNzI3NDA3MTU0NjUxMDU2NjY3MjY2NTYyNTIxNjAwMDI4MTMxNDY3NTk0MTMxMjQ5NjU3MjcwNjQ2MDUzMTU0MjE4MTg5Mzg3NzI4NjU5MjEwMzM0NDcyNjg1NDY5MjQ0NTEwNzQxMzU5MzkzNjIxNDMzNjMyMTA2NA==",
                      "ODQ3MjA0OTg1OTk2Mjc3MzY3NjIxMzAxMTEwMzIxMjI1NTk2Mjc1OTgzMjQ5MDYwNTgwMzUzMDcxMzg4MTk1NDQ3NDUwNDg1NDEwNzQ=",
                      "MjE1NjcyMjkyNTU1NjI5Mzg4NzgxNDg4MzA1ODk4NzQ4MDU2ODY3OTI4NjQ5MzcwNDg3MzQzNDkxMjcxMTc3MTUwNjQzNTkyOTAzMTU=",
                      "VDAyMWQyNDk3YTVjZmFlNGNhMmU3ZDFmNzcyMTdhNDNlM2VjOWU2MGVjMWM3NjY2")
end

def a_fixed_signed_transaction
  sender_wallet = a_fixed_sender_wallet

  recipient_wallet = Wallet.new("MTMwNzg1MjY3Nzk5Nzg3NTUxMDM2NTY0MDkxODMxNDQzMzE5MDg3NjEzMTY1NDg5MTY2NTAyMjcxMzUxMDgxMzA0ODM2MDkyOTA5MTgwMjMxNTk1NDYwNDc4NDAyNzYwMDAyMjUwMzI2ODA5NDc2OTM2NTI0MTQ5MzIyNDI0NDY4MjI5MDEzMDM1OTA2MDg2ODE1MjE3MzU3MTk=",
                      "ODYzMTIyOTk1MjE4Mzk0NDE5ODUxNjMyOTkzMTQ5MjM5NjE2MDgyMjc5Mzg2OTcyNzkxMzYxNDc4MzU2OTY3MzcyODI4Mjg3MTM0OTQ=",
                      "MzIzMzQyMTI3NDEzNDM2NjQwMzg1Njc0MDY5ODg3ODk3MTU0MTQ5NTU2OTc5MjM0ODI4ODA1ODcwNDM0NTg3ODkzOTg4MDc4MTEwMDI=",
                      "VDBlMWQ2YTYyYTZiMTVjZjc1MTQ2NDJlMjgwNjA5ZTMyOGU3NTE5YTRhMWI3NjY1")

  unsigned_transaction = Transaction.new(
    "ded1ea5373f55b4e84ea9c140761ba181af31a94cc6c2bb22685b2f86639ca1e",
    "send", # action
    [ a_sender(sender_wallet, 1000.00) ],
    [ a_recipient(recipient_wallet, 10.00) ],
    "0", # message
    "0", # prev_hash
    "0", # sign_r
    "0", # sign_s
  )

  unsigned_transaction.signed("cd5927cdc4cf789af690fb5dcd8fd8ec64e9155d9cb025ed93962d686b5d823a","ef991d40c9a74079ae64c3a351f733134fc50fe92628f66f3b97a42610521c06")
end
