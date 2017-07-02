#!/bin/bash

################# 解析の流れ ###################
# -------- I. アライメント（マッピング） --------
# I-1. リファレンスのインデックスファイルを作成（bowtie2-build）
# I-2. アライメント（bowtie2）
# I-3. アライメント結果のフォーマット変換（samtools view）
# I-4. アライメント結果の並べ替え（samtools sort）
# I-5. IGV用インデックスファイル作成（samtools index, samtools faidx）
# -------- II. 発現比較 --------
# II-1. アライメント結果からGTFファイルを取得（cufflinks）
# II-2. 複数のGTFファイルを統合（cuffmerge）
# II-3. 統合GTFファイルを元に、発現量を計算（cuffquant）
# II-4. 発現比較（cuffdiff）
##############################################

# -------- 入力データ --------
# リファレンス
ref_dir="./00_input_data/01_reference"
ref_fasta="${ref_dir}/ilas2017_example.fasta"
ref_index="${ref_dir}/ilas2017_example"

# RNA-seqデータ
reads_dir="./00_input_data/02_reads"

# -------- 出力先 --------
bwt_out="./01_alignment"

cufflinks_out="./02_cufflinks_out"
cuffmerge_out="./03_cuffmerge_out"
cuffquant_out="./04_cuffquant_out"
cuffdiff_out="./05_cuffdiff_out"

# -------- コマンド --------
# I-1. リファレンスのインデックスファイルを作成（bowtie2-build）
bowtie2-build -f "${ref_fasta}" "${ref_index}"

# I-2 ~ II-1
for i in "sample_01" "sample_02";do

    # I-2. アライメント（bowtie2）
    # Bowtieアウトプットディレクトリを作成
    mkdir -p "${bwt_out}"
    # Bowtie実行
    bowtie2 \
        -x "${ref_index}" \
        -1 "${reads_dir}/${i}_1.fastq.gz" \
        -2 "${reads_dir}/${i}_2.fastq.gz" \
        -S "${bwt_out}/${i}.sam"

    # I-3. アライメント結果のフォーマット変換（samtools view）
    samtools view -bS "${bwt_out}/${i}.sam" > "${bwt_out}/${i}.bam"

    # I-4. アライメント結果の並べ替え（samtools sort）
    samtools sort "${bwt_out}/${i}.bam" > "${bwt_out}/${i}.sorted.bam"
    #不要ファイル削除
    rm -f "${bwt_out}/${i}.sam" "${bwt_out}/${i}.bam"

    # I-5. IGV用インデックスファイル作成（samtools index, samtools faidx）
    samtools index "${bwt_out}/${i}.sorted.bam"
    samtools faidx "${ref_fasta}"

    # II-1. アライメント結果からGTFファイルを取得（cufflinks）
    cufflinks -L ${i} \
        -o "${cufflinks_out}/${i}" \
        "${bwt_out}/${i}.sorted.bam"

    # GTFファイルリストの作成（II-2で使用）
    ls "${cufflinks_out}/${i}/transcripts.gtf" >> "${cufflinks_out}/gtflist.txt"

done

# II-2. 複数のGTFファイルを統合（cuffmerge）
cuffmerge \
    --ref-sequence ${ref_fasta} \
    -o "${cuffmerge_out}" "${cufflinks_out}/gtflist.txt"

# II-3. 統合GTFファイルを元に、発現量を計算（cuffquant）
for i in "sample_01" "sample_02";do
    cuffquant \
        -o "${cuffquant_out}/${i}" \
        "${cuffmerge_out}/merged.gtf" \
        "${bwt_out}/${i}.sorted.bam"
done

# II-4. 発現比較（cuffdiff）
cuffdiff -o "${cuffdiff_out}" \
    -L red_perilla,green_perilla \
    "${cuffmerge_out}/merged.gtf" \
    "${cuffquant_out}/sample_01/abundances.cxb" \
    "${cuffquant_out}/sample_02/abundances.cxb"
