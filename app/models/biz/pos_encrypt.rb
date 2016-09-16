module Biz
  class PosEncrypt
    def self.test_data
      key = 'AB73C9416D41E936E82AAC11053BCEDD'
      mab = '20160913201609132016091320160913'
      puts "key = " + key
      puts "mab = " + mab
      puts "result = " + pos_ecb(mab, key)
    end
    def self.test_data1
      key = '2222222222222222'
      mab = ['1234567890ABCDEFABCDEF1234567890'].pack('H*')
      puts "key = " + key
      puts "mab = " + mab.unpack('H*')[0]
      puts "result = " + pos_ecb(mab, key)
    end
    def self.pos_ecb(mab_string, key)
      result_block = xor_8(mab_string)
      result_block_hex = result_block.unpack('H*')[0]
      enc_block1 = encrypt_mak(result_block_hex[0..7], key)
      temp_block = xor_8(enc_block1[0..7] + result_block_hex[8..16])
      enc_block2 = encrypt_mak(temp_block, key)
      enc_block2 = enc_block2.unpack('H*')[0]
      mac = enc_block2[0..7]
      puts "result_block: " + result_block.unpack('H*')[0]
      puts "result_block_hex: " + result_block_hex
      puts "enc_block1: " + enc_block1.unpack('H*')[0]
      puts "temp_block: " + temp_block
      puts "enc_block2: " + enc_block2
      mac
    end
    def self.xor_8(input_string)
      bs = input_string.bytes
      result_block = []
      (0..7).each do |i|
        result_block << cal_xor(bs, i)
      end
      result_block.pack('C*')
    end
    def self.cal_xor(arr, idx)
      len = arr.length
      i = idx
      r = 0
      while i < len do
        r = r ^ arr[i]
        i += 8
      end
      r
    end
    def self.encrypt_mak(str, key)
      cipher = OpenSSL::Cipher.new 'des'
      cipher.encrypt
      cipher.key = key
      cipher.update(str) + cipher.final
    end
  end
end
