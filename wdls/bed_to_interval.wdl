version 1.0

task bed_to_interval_ {
	input {
		File bed
		File bam
	}

	command <<<
		java -jar /home/picard/build/libs/picard.jar \
		BedToIntervalList \
		--INPUT ~{bed} \
		--SEQUENCE_DICTIONARY ~{bam} \
		--OUTPUT list.interval_list
	>>>

	output {
		File list = "list.interval_list"
	}

	runtime {
		docker: "developmentontheedge/picard:0.1"
	}
}

workflow bed_to_interval {
	input {
		File bed
		File bam
	}

	call bed_to_interval_ {
		input:
		bed = bed,
		bam = bam
	}

	output {
		File interval_list = bed_to_interval_.list
	}
}
