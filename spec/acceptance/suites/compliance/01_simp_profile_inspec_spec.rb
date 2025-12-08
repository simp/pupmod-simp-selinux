require 'spec_helper_acceptance'
require 'json'

test_name 'Check Inspec for simp profile'

describe 'run inspec against the appropriate fixtures' do
  profiles_to_validate = ['disa_stig']

  hosts.each do |host|
    profiles_to_validate.each do |profile|
      context "for profile #{profile}" do
        context "on #{host}" do
          profile_path = File.join(
            fixtures_path,
            'inspec_profiles',
            "#{fact_on(host, 'os.name')}-#{fact_on(host, 'os.release.major')}-#{profile}",
          )

          if File.exist?(profile_path)
            let(:inspec) do
              Simp::BeakerHelpers::Inspec.enable_repo_on(hosts)
              Simp::BeakerHelpers::Inspec.new(host, profile)
            end

            let(:inspec_report_data) do
              inspec.run
              inspec.process_inspec_results
            end

            it 'runs inspec successfully' do
              expect { inspec.run }.not_to raise_error
            end

            it 'has an inspec report' do
              info = [
                'Results:',
                "  * Passed: #{inspec_report_data[:passed]}",
                "  * Failed: #{inspec_report_data[:failed]}",
                "  * Skipped: #{inspec_report_data[:skipped]}",
              ]

              puts info.join("\n")

              inspec.write_report(inspec_report_data)
            end

            it 'has run some tests' do
              expect(inspec_report_data[:failed] + inspec_report_data[:passed]).to be > 0
            end

            it 'does not have any failing tests' do
              if inspec_report_data[:failed] > 0
                puts inspec_report_data[:report]
              end

              expect(inspec_report_data[:failed]).to eq(0)
            end
          else
            it 'runs inspec without a matching profile' do
              skip("No matching profile available at #{profile_path}")
            end
          end
        end
      end
    end
  end
end
