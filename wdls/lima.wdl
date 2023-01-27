version 1.0
task lima_demultiplex {
        input {
                File reads_ccs_bam
                File isoseq_primers_fasta
                String bool
        }

        String reads_demult_bam = "lima_output.fastq"
        String prefix = sub(reads_demult_bam, ".bam", "")
	
        command <<<
                if [["~{bool}" = "true"]]; then
                lima --dump-clips --peek-guess -j 16 ~{reads_ccs_bam} ~{isoseq_primers_fasta} ~{reads_demult_bam}
                else
                mv ~{reads_ccs_bam} "lima_output.5p--3p.bam"
                fi
        >>>

        output {
                File fivep__3p_bam = "lima_output.5p--3p.bam"
#                File? fivep__3p_bam_pbi = "${prefix}.5p--3p.bam.pbi"
#                File? fivep__3p_consensusreadset_xml = "${prefix}.5p--3p.consensusreadset.xml"
#                File? consensusreadset_xml = "${prefix}.consensusreadset.xml"
#                File? json = "${prefix}.json"
#                File? lima_clips = "${prefix}.lima.clips"
#                File? lima_counts = "${prefix}.lima.counts"
#                File? lima_guess = "${prefix}.lima.guess"
#                File? lima_report = "${prefix}.lima.report"
#                File? lima_summary = "${prefix}.lima.summary"
        }

        runtime {
                docker: "developmentontheedge/lima:0.1"
        }
}

workflow lima {
        input {
                File reads_ccs_bam
                File isoseq_primers_fasta
                String bool
        }

        call lima_demultiplex {
                input:
                bool = bool,
                reads_ccs_bam=reads_ccs_bam,
                isoseq_primers_fasta=isoseq_primers_fasta,
        }

        output {
                File fivep__3p_bam = lima_demultiplex.fivep__3p_bam
#                File fivep__3p_bam_pbi = lima_demultiplex.fivep__3p_bam_pbi
#                File fivep__3p_consensusreadset_xml = lima_demultiplex.fivep__3p_consensusreadset_xml
#                File consensusreadset_xml = lima_demultiplex.consensusreadset_xml
#                File json = lima_demultiplex.json
#                File lima_clips = lima_demultiplex.lima_clips
#                File lima_counts = lima_demultiplex.lima_counts
#                File lima_guess = lima_demultiplex.lima_guess
#                File lima_report = lima_demultiplex.lima_report
#                File lima_summary = lima_demultiplex.lima_summary
        }

        meta {
                description: "##"
        }
}
