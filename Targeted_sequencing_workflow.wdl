version 1.0

import "wdls/lima.wdl" as lima
import "wdls/pbmarkdup.wdl" as pbmarkdup
import "wdls/pbmm2.wdl" as pbmm2
import "wdls/pbsv.wdl" as pbsv
import "wdls/deepvariant.wdl" as deepvariant
import "wdls/phase.wdl" as phase
import "wdls/stats.wdl" as stats
import "wdls/haplotag.wdl" as haplotag
import "wdls/bgzip.wdl" as bgzip
import "wdls/unzip.wdl" as unzip
import "wdls/tabix.wdl" as tabix
import "wdls/primrose.wdl" as primrose
import "wdls/samtools_faidx.wdl" as samtools_faidx
import "wdls/bed_to_interval.wdl" as bed_to_interval
import "wdls/collect_metrics.wdl" as collect_metrics
import "wdls/multiqc.wdl" as multiqc
import "wdls/survivor.wdl" as survivor

workflow targeted_sequencing {
	input {
		File primers_fasta
		File ref_fasta
		File bam
		String lima_bool = "false"

		Array[String] regions_pbsv
		String regions_deepvariant
		File tr_bed

		File gene_bed
		File region_fasta
		File bait_bed
	}

	call samtools_faidx.call_samtools_faidx as faidx {
		input:
		reference_fasta = ref_fasta
	}

	call samtools_faidx.call_samtools_faidx as faidx1 {
		input:
		reference_fasta = region_fasta
	}

	File ref_fasta_fai = faidx.fai
	File region_fasta_fai = faidx1.fai

	call lima.lima as lima_ {
		input:
		bool = lima_bool,
		reads_ccs_bam = bam,
		isoseq_primers_fasta = primers_fasta
	}

	File lima_bam = lima_.fivep__3p_bam

	call pbmarkdup.pbmarkdup as pbmarkdup_ {
		input:
		bam = bam
	}

	File pbmarkdup_bam = pbmarkdup_.out_bam

	call pbmm2.run_pbmm2 as align {
		input:
		sample_name = "a",
		reference_name = "hg38",
		reference_fasta = ref_fasta,
		reference_index = ref_fasta_fai,
		movies = [pbmarkdup_bam]
	}

	Array[File] bams = align.bams
	Array[File] bais = align.bais

	call pbsv.run_pbsv as call_svc {
		input:
		sample_name = "a",
		bams = bams,
		bais = bais,
		reference_name = "hg38",
		reference_fasta = ref_fasta,
		reference_index = ref_fasta_fai,
		regions = regions_pbsv,
		tr_bed = tr_bed
	}

	File svcs = call_svc.vcf

	call unzip.unzip as unzip_ {
		input:
		vcf_gz = svcs
	}

	call survivor.survivor as survivor_ {
		input:
		vcf = unzip_.vcf
	}

	File aligned_bam = bams[0]
	File aligned_bam_bai = bais[0]

	call deepvariant.call_deepvariant as call_snps {
		input:
		model_type = "PACBIO",
		reference_fasta = ref_fasta,
		reference_index = ref_fasta_fai,
		reads_bam = aligned_bam,
		reads_index = aligned_bam_bai,
		regions = regions_deepvariant,
		output_vcf_path = "deepvariant_snp.vcf",
		num_shards = 2
	}

	File vcf = call_snps.snp_vcf

	call phase.phase as phase_ {
		input:
		ref_fasta = ref_fasta,
		ref_fasta_fai = ref_fasta_fai,
		bam = aligned_bam,
		bam_bai = aligned_bam_bai,
		vcf = vcf
	}

	File phased_vcf = phase_.phased_vcf

	call bgzip.bgzip as bgzip_ {
		input:
		vcf = phased_vcf
	}

	File phased_vcf_gz = bgzip_.vcf_gz

	call tabix.tabix as tabix_ {
		input:
		vcf_gz = phased_vcf_gz
	}

	File phased_vcf_gz_tbi = tabix_.vcf_gz_tbi

	call haplotag.haplotag as haplotag_ {
		input:
		ref_fasta = ref_fasta,
		ref_fasta_fai = ref_fasta_fai,
		vcf_gz = phased_vcf_gz,
		vcf_gz_tbi = phased_vcf_gz_tbi,
		bam = aligned_bam,
		bam_bai = aligned_bam_bai
	}

	File haplotagged_bam = haplotag_.haplotagged_bam

	# call bed to list x 2 + call collect metrics

	call bed_to_interval.bed_to_interval as bed_to_interval1 {
		input:
		bed = gene_bed,
		bam = bam
	}

	call bed_to_interval.bed_to_interval as bed_to_interval2 {
		input:
		bed = bait_bed,
		bam = bam
	}

	File gene_interval_list = bed_to_interval1.interval_list
	File bait_interval_list = bed_to_interval2.interval_list

	call collect_metrics.collect_metrics as collect_metrics_ {
		input:
		bam = bam,
		ref_seq = region_fasta,
		ref_seq_fai = region_fasta_fai,
		target_intervals = gene_interval_list,
		bait_intervals = bait_interval_list
	}

	call multiqc.multiqc as multiqc {
		input:
		picard_txt = collect_metrics_.report
	}

	output {
		File aligned_bam_ = haplotagged_bam
		File snp_vcf = call_snps.snp_vcf
		File svc_vcf = unzip_.vcf
		File svc_report_txt = survivor_.report_txt
		File picard_report = collect_metrics_.report
		File multiqc_report = multiqc.html
	}
}
