require 'couchbase'

$sonnet =
  "Then hate me when thou wilt if ever now " +
  "Now while the world is bent my deeds to cross " +
  "Join with the spite of fortune make me bow " +
  "And do not drop in for an after-loss " +
  "Ah do not when my heart hath 'scaped this sorrow " +
  "Come in the rearward of a conquered woe " +
  "Give not a windy night a rainy morrow " +
  "To linger out a purposed overthrow " +
  "If thou wilt leave me do not leave me last " +
  "When other petty griefs have done their spite " +
  "But in the onset come so shall I taste " +
  "At first the very worst of fortune's might " +
  "And other strains of woe which now seem woe " +
  "Compared with loss of thee will not seem so"

$words = $sonnet.downcase.split(" ")
$prng = Random.new

def rand_word
  $words[$prng.rand(0..$words.length - 1)]
end

def gen_key
  rand_word + "_" + rand_word + "_" + rand_word
end

def gen_string
  len = $prng.rand(3..10)
  wlen = $words.length - len
  start = $prng.rand(0..wlen - 1)
  $words[start, len].join(" ")
end

def gen_doc(max)
  nKeys = $prng.rand(1..max)
  doc = {}
  nKeys.times do
    if nKeys > 1
      doc[gen_key] = gen_doc(nKeys - 1)
    else
      doc[gen_key] = gen_string
    end
  end
  doc
end

$to_remove = []

c = Couchbase.connect("http://localhost:9000/pools/default/buckets/default")
10000.times do |n|
  key = gen_key
  puts n.to_s + ". key = " + key
  c.set(key, gen_doc(10))
  if $prng.rand(0..2) == 0
    $to_remove << key
  end
end

$to_remove.each do |key|
  puts "remove key = " + key
  begin
    c.delete(key)
  rescue
    puts "unable to remove key " + key
  end
end
