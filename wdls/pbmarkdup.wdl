version 1.0

task mark_duplicates {
	input {
		File bam
	}

	String out = "pbmarkdup_out.bam"

	command <<<
		pbmarkdup ~{bam} ~{out} --ignore-read-names
	>>>

	output {
		File out_bam = "${out}"
	}

	runtime {
		docker: "developmentontheedge/pbmarkdup:0.1"
	}
}

workflow pbmarkdup {
	input {
		File bam
	}

	call mark_duplicates {
		input:
		bam = bam
	}

	output {
		File out_bam = mark_duplicates.out_bam
	}
}
