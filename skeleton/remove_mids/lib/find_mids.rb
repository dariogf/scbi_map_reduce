require 'scbi_blast'
require 'global_match'
# require 'json'

# Module to find Mids in a set of sequences
module FindMids

  # find mids using blast+ as an external tool
  def find_mid_with_blast(seqs)
    t=Time.now

    # Create blast machine agains mid database
    blast = BatchBlast.new("-db #{File.expand_path(File.join(File.dirname(__FILE__),'db/mids.fasta'))}",'blastn'," -task blastn-short    -perc_identity 95 -max_target_seqs 4 ")  #get mids

    # build fastas to blast
    fastas=[]

    seqs.each do |name,fasta,qual,comments|
      fastas.push ">"+name
      fastas.push fasta
    end

    # execute blast
    blast_table_results = blast.do_blast(fastas)

    # puts blast_table_results.inspect

    # Iterate over blast results and sequences
    i=0
    seqs.each do |name,fasta,qual,comments|
      parse_seq(blast_table_results.querys[i],name,fasta,qual,comments)
      i+=1
    end

    elapsed=Time.now-t

    puts "T:#{elapsed}, rate#{elapsed/seqs.count}"

  end


  # parse blast results and sequences to remove found MIDS
  def parse_seq(query,name,fasta,qual,comments)

    # find_polys('TN',fasta)
    #     find_polys('AN',fasta)

    query.hits.each do |found_mid|

      if found_mid.align_len>1

        # modify comments by appending removed mid
        comments << found_mid.subject_id

        # keep fasta from pos to end
        fasta.slice!(0, found_mid.q_beg + found_mid.align_len)

        # keep qual from pos to end
        qual.slice!(0, found_mid.q_beg + found_mid.align_len)
        break
      end
    end
  end

  def find_mid_without_blast(seqs)
    # those are the mids found in database
    t=Time.now

    mids={}
    mids['RL1']='ACACGACGACT'
    mids['RL2']='ACACGTAGTAT'
    mids['RL3']='ACACTACTCGT'
    mids['RL4']='ACGACACGTAT'
    mids['RL5']='ACGAGTAGACT'
    mids['RL6']='ACGCGTCTAGT'
    mids['RL7']='ACGTACACACT'
    mids['RL8']='ACGTACTGTGT'
    mids['RL9']='ACGTAGATCGT'
    mids['RL10']='ACTACGTCTCT'
    mids['RL11']='ACTATACGAGT'
    mids['RL12']='ACTCGCGTCGT'
    mids['MID1']='ACGAGTGCGT'
    mids['MID2']='ACGCTCGACA'
    mids['MID3']='AGACGCACTC'
    mids['MID5']='ATCAGACACG'
    mids['MID6']='ATATCGCGAG'
    mids['MID7']='CGTGTCTCTA'
    mids['MID8']='CTCGCGTGTC'
    mids['MID10']='TCTCTATGCG'
    mids['MID11']='TGATACGTCT'
    mids['MID13']='CATAGTAGTG'
    mids['MID14']='CGAGAGATAC'
    mids['MID15']='ATACGACGTA'
    mids['MID16']='TCACGTACTA'
    mids['MID17']='CGTCTAGTAC'
    mids['MID18']='TCTACGTAGC'
    mids['MID19']='TGTACTACTC'
    mids['MID20']='ACGACTACAG'
    mids['MID21']='CGTAGACTAG'
    mids['MID22']='TACGAGTATG'
    mids['MID23']='TACTCTCGTG'
    mids['MID24']='TAGAGACGAG'
    mids['MID25']='TCGTCGCTCG'
    mids['MID26']='ACATACGCGT'
    mids['MID27']='ACGCGAGTAT'
    mids['MID28']='ACTACTATGT'
    mids['MID68']='TCGCTGCGTA'
    mids['MID30']='AGACTATACT'
    mids['MID31']='AGCGTCGTCT'
    mids['MID32']='AGTACGCTAT'
    mids['MID33']='ATAGAGTACT'
    mids['MID34']='CACGCTACGT'
    mids['MID35']='CAGTAGACGT'
    mids['MID36']='CGACGTGACT'
    mids['MID37']='TACACACACT'
    mids['MID38']='TACACGTGAT'
    mids['MID39']='TACAGATCGT'
    mids['MID40']='TACGCTGTCT'
    mids['MID69']='TCTGACGTCA'
    mids['MID42']='TCGATCACGT'
    mids['MID43']='TCGCACTAGT'
    mids['MID44']='TCTAGCGACT'
    mids['MID45']='TCTATACTAT'
    mids['MID46']='TGACGTATGT'
    mids['MID47']='TGTGAGTAGT'
    mids['MID48']='ACAGTATATA'
    mids['MID49']='ACGCGATCGA'
    mids['MID50']='ACTAGCAGTA'
    mids['MID67']='TCGATAGTGA'

    # for each sequence
    seqs.each do |name,fasta,qual,comment|
      
      # find all mids
      mids.each do |mid_name,mid|
        # puts "."
        # find a known MID position
        found_mid=fasta[0..20].lcs(mid)
        # puts "."
        # puts pos.to_json
        if found_mid.length>5

          pos=fasta[0..20].index(found_mid)
          # puts found_mid,pos
          # keep fasta from pos to end
          fasta.slice!(0,pos+found_mid.length)

          # keep qual from pos to end
          qual.slice!(0,pos+found_mid.length)

          comment << "mid_name #{mid_name}\n"
          # puts comment
          break
        end
      end
    end

    elapsed=Time.now-t

    puts "T:#{elapsed}, rate#{elapsed/seqs.count}"

  end


  def do_dummy_calculation
    numer_of_calcs=250000

    t=Time.now

    x1=1
    x2=1

    # do a loop with calculations
    numer_of_calcs.times do |i|
      x=x1+x2

      x1=x2
      x2=x

      # puts some info at regular intervals
      if (i % 100000)==0
        puts "Calculated #{i} by thread #{n}"
      end
    end
    puts Time.now-t

  end



end
