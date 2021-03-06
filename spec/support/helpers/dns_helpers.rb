# frozen_string_literal: true

module DnsHelpers
  def block_dns!
    stub_all_dns!
    stub_invalid_dns!
    permit_local_dns!
  end

  def permit_dns!
    allow(Addrinfo).to receive(:getaddrinfo).and_call_original
  end

  def stub_all_dns!
    allow(Addrinfo).to receive(:getaddrinfo).with(anything, anything, nil, :STREAM).and_return([])
    allow(Addrinfo).to receive(:getaddrinfo).with(anything, anything, nil, :STREAM, anything, anything).and_return([])
  end

  def stub_invalid_dns!
    allow(Addrinfo).to receive(:getaddrinfo).with(/\Afoobar\.\w|(\d{1,3}\.){4,}\d{1,3}\z/i, anything, nil, :STREAM) do
      raise SocketError, "getaddrinfo: Name or service not known"
    end
  end

  def permit_local_dns!
    local_addresses = %r{
      \A
      ::1? |                                    # IPV6
      (127|10)\.0\.0\.\d{1,3} |                 # 127.0.0.x or 10.0.0.x local network
      (192\.168|172\.16)\.\d{1,3}\.\d{1,3} |    # 192.168.x.x or 172.16.x.x local network
      0\.0\.0\.0 |                              # loopback
      localhost
      \z
    }xi
    allow(Addrinfo).to receive(:getaddrinfo).with(local_addresses, anything, nil, :STREAM).and_call_original
    allow(Addrinfo).to receive(:getaddrinfo).with(local_addresses, anything, nil, :STREAM, anything, anything, any_args).and_call_original
  end
end
