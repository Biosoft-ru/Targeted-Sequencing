version 1.0

task multiqc_ {
	input {
		File picard_txt
	}

	command <<<
		multiqc ~{picard_txt} -o .
	>>>

	output {
		File html = "multiqc_report.html"
	}

	runtime {
		docker: "developmentontheedge/multiqc:latest"
	}
}

workflow multiqc {
	input {
		File picard_txt
	}

	call multiqc_ {
		input:
		picard_txt = picard_txt
	}

	output {
		File html = multiqc_.html
	}
}
