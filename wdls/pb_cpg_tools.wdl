version 1.0

task pb_cpg_tools_ {
	input {
		File ref_fasta
		File bam
		File bam_bai
		String label = "out"
	}

	command <<<
		ln -s ~{bam_bai} "~{bam}.bai"
		source activate cpg
		python /home/pb-CpG-tools/aligned_bam_to_cpg_scores.py \
		-b ~{bam} \
		-f ~{ref_fasta} \
		-o ~{label} \
		-d /home/pb-CpG-tools/pileup_calling_model/
	>>>

	output {
		File combined_bed = "${label}.combined.denovo.bed"
		File hap1_bed = "${label}.hap1.denovo.bed"
		File hap2_bed = "${label}.hap2.denovo.bed"
		File hap1_bw = "${label}.hap1.denovo.bw"
		File hap2_bw = "${label}.hap2.denovo.bw"
	}

	runtime {
		docker: "developmentontheedge/pb_cpg_tools:0.1"
	}
}

workflow pb_cpg_tools {
	input {
		File ref_fasta
		File bam
		File bam_bai
		String label = "out"
	}

	call pb_cpg_tools_ {
		input:
		ref_fasta = ref_fasta,
		bam = bam,
		bam_bai = bam_bai,
		label = label
	}

	output {
		File combined_bed = pb_cpg_tools_.combined_bed
		File hap1_bed = pb_cpg_tools_.hap1_bed
		File hap2_bed = pb_cpg_tools_.hap2_bed
		File hap1_bw = pb_cpg_tools_.hap1_bw
		File hap2_bw = pb_cpg_tools_.hap2_bw
	}
}
