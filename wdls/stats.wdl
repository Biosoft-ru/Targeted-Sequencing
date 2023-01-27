version 1.0

task stats_ {
	input {
		File vcf
	}

	command <<<
		source activate whp
		whatshap stats ~{vcf} > output.txt
	>>>

	output {
		File out_txt = "output.txt"
	}

	runtime {
		docker: "developmentontheedge/whatshap:latest"
	}
}

workflow stats {
	input {
		File vcf
	}

	call stats_ {
		input:
		vcf=vcf
	}

	output {
		File out_txt = stats_.out_txt
	}
}
