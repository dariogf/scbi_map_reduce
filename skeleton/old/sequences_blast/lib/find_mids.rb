require 'scbi_blast'
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

    puts blast_table_results.inspect

    # Iterate over blast results and sequences
    i=0
    seqs.each do |name,fasta,qual,comments|
      parse_seq(blast_table_results.querys[i],name,fasta,qual,comments)
      i+=1
    end

    puts Time.now-t

  end


  # parse blast results and sequences to remove found MIDS
  def parse_seq(query,name,fasta,qual,comments)

    query.hits.each do |found_mid|

      if found_mid.align_len>7

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
    mids['MID4']='AGCACTGTAG'
    mids['MID5']='ATCAGACACG'
    mids['MID6']='ATATCGCGAG'
    mids['MID7']='CGTGTCTCTA'
    mids['MID8']='CTCGCGTGTC'
    mids['MID9']='TAGTATCAGC'
    mids['MID10']='TCTCTATGCG'
    mids['MID11']='TGATACGTCT'
    mids['MID12']='TACTGAGCTA'

    mids.each do |mid_name,mid|

      seqs.each do |name,fasta,qual,comment|

        # find a known MID position
        pos=fasta.upcase.index(mid)

        if pos

          # keep fasta from pos to end
          fasta.slice!(0,pos+mid.length)

          # keep qual from pos to end
          qual.slice!(0,pos+mid.length)

        end
      end
    end

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
