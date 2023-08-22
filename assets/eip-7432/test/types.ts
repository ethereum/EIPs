export interface NftMetadata {
  name: string
  description: string
  roles: Role[]
}

export interface Role {
  name: string
  description: string
  supportsMultipleAssignments: boolean
  inputs: Input[]
}

export interface Input {
  name: string
  type: string
  components?: Input[]
}
