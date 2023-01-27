version 1.0

import "lima.wdl" as lima
import "pbmarkdup.wdl" as pbmarkdup
import "pbmm2_1.wdl" as pbmm2
import "pbsv.wdl" as pbsv
import "deepvariant_1.wdl" as deepvariant
import "phase.wdl" as phase
import "stats.wdl" as stats
import "haplotag.wdl" as haplotag
import "bgzip.wdl" as bgzip
import "tabix.wdl" as tabix
import "primrose.wdl" as primrose
import "samtools_faidx.wdl" as samtools_faidx
import "bed_to_interval.wdl" as bed_to_interval
import "collect_metrics.wdl" as collect_metrics

workflow targeted_sequencing {
	input {
		File primers_fasta
		File ref_fasta
		File bam
		String lima_bool

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
		output_vcf_path = "out.vcf",
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

	output {
		File aligned_bam_ = align.bams[0]
		File snp_vcf = call_snps.snp_vcf
		File svc_vcf = call_svc.vcf
		File picard_report = collect_metrics_.report
	}
}
