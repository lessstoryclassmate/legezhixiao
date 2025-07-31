import React from 'react'
import { useParams } from 'react-router-dom'
import { useAppStore } from '../store/appStore'
import CreativeToolsManager from '../components/Writing/CreativeToolsManager'

const CreativeToolsPage: React.FC = () => {
  const { id } = useParams<{ id: string }>()
  const { projects } = useAppStore()
  
  const currentProject = projects.find(p => p.id === id)

  return (
    <CreativeToolsManager currentProject={currentProject} />
  )
}

export default CreativeToolsPage
