version 1.0

task collect_metrics_ {
	input {
		File bam
		File ref_seq
		File ref_seq_fai
		File target_intervals
		File bait_intervals
	}

	command <<<
		ln -s ~{ref_seq_fai} "~{ref_seq}.fai"
		java -jar /home/picard/build/libs/picard.jar CollectHsMetrics \
		--INPUT ~{bam} \
		--OUTPUT picard_output.txt \
		--REFERENCE_SEQUENCE ~{ref_seq} \
		--TARGET_INTERVALS ~{target_intervals} \
		--BAIT_INTERVALS ~{bait_intervals}
	>>>

	output {
		File report = "picard_output.txt"
	}

	runtime {
		docker: "developmentontheedge/picard:0.1"
	}
}

workflow collect_metrics {
	input {
		File bam
		File ref_seq
		File ref_seq_fai
		File target_intervals
		File bait_intervals
	}

	call collect_metrics_ {
		input:
		bam = bam,
		ref_seq = ref_seq,
		ref_seq_fai = ref_seq_fai,
		target_intervals = target_intervals,
		bait_intervals = bait_intervals
	}

	output {
		File report = collect_metrics_.report
	}
}
